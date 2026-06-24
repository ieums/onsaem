package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.entity.Account;
import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.PasswordResetCode;
import com.ieum.backend.domain.auth.entity.Student;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.PasswordResetCodeRepository;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.global.exception.BusinessException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.UnsupportedEncodingException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 비밀번호 재설정(이메일 인증 코드) — LOCAL(이메일가입) 계정만 대상.
 * 소셜 계정은 우리 DB에 비밀번호가 없으므로 코드 발송 자체를 하지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final StudentRepository studentRepository;
    private final TutorRepository tutorRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;

    @Value("${password-reset.mail-enabled:false}")
    private boolean mailEnabled;
    @Value("${password-reset.from:ieum.team@gmail.com}")
    private String from;
    @Value("${password-reset.code-ttl-minutes:10}")
    private long ttlMinutes;

    /**
     * 재설정 코드 발송. 계정이 없거나 소셜 계정이어도 동일하게 200을 반환해
     * 이메일 가입 여부가 외부에 노출되지 않도록 한다(계정 열거 방지).
     */
    @Transactional
    public void requestReset(String email) {
        Optional<? extends Account> account = findLocalAccount(email);
        if (account.isEmpty()) {
            log.info("[비밀번호 재설정] 대상 LOCAL 계정 없음(또는 소셜): {}", email);
            return;
        }

        String code = generateCode();
        codeRepository.save(PasswordResetCode.builder()
                .email(email)
                .codeHash(passwordEncoder.encode(code))
                .expiresAt(LocalDateTime.now().plusMinutes(ttlMinutes))
                .build());

        sendCodeEmail(email, code);
    }

    /** 코드 검증 후 새 비밀번호로 변경. */
    @Transactional
    public void confirmReset(String email, String code, String newPassword) {
        PasswordResetCode reset = codeRepository
                .findFirstByEmailOrderByCreatedAtDesc(email)
                .orElseThrow(() -> BusinessException.badRequest("인증 코드가 올바르지 않습니다."));

        if (reset.isConsumed()) {
            throw BusinessException.badRequest("이미 사용된 인증 코드입니다.");
        }
        if (reset.isExpired(LocalDateTime.now())) {
            throw BusinessException.badRequest("인증 코드가 만료되었습니다. 다시 요청해 주세요.");
        }
        if (!passwordEncoder.matches(code, reset.getCodeHash())) {
            throw BusinessException.badRequest("인증 코드가 올바르지 않습니다.");
        }

        Account account = findLocalAccount(email)
                .orElseThrow(() -> BusinessException.badRequest("인증 코드가 올바르지 않습니다."));
        account.changePassword(passwordEncoder.encode(newPassword));
        reset.consume();
    }

    /** 학생→강사 순으로 LOCAL 계정을 찾는다. */
    private Optional<? extends Account> findLocalAccount(String email) {
        Optional<Student> student = studentRepository.findByEmail(email);
        if (student.isPresent() && student.get().getProvider() == AuthProvider.LOCAL) {
            return student;
        }
        Optional<Tutor> tutor = tutorRepository.findByEmail(email);
        if (tutor.isPresent() && tutor.get().getProvider() == AuthProvider.LOCAL) {
            return tutor;
        }
        return Optional.empty();
    }

    private String generateCode() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    private void sendCodeEmail(String to, String code) {
        if (!mailEnabled) {
            // 로컬 테스트: 실제 발송 대신 콘솔에 코드 출력
            log.info("[비밀번호 재설정] (mail-enabled=false) {} 인증 코드: {}", to, code);
            return;
        }
        JavaMailSender sender = mailSenderProvider.getIfAvailable();
        if (sender == null) {
            log.warn("[비밀번호 재설정] mail-enabled=true 이지만 JavaMailSender 미구성. 코드: {}", code);
            return;
        }
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
            helper.setFrom(from, "온샘");
            helper.setTo(to);
            helper.setSubject("[온샘] 비밀번호 재설정 인증 코드");
            helper.setText(buildEmailHtml(code), true); // true = HTML 본문
            sender.send(message);
        } catch (MessagingException | UnsupportedEncodingException e) {
            log.error("[비밀번호 재설정] 메일 발송 실패: {}", e.getMessage());
            throw BusinessException.badRequest("인증 메일 발송에 실패했습니다. 잠시 후 다시 시도해 주세요.");
        }
    }

    /**
     * 비밀번호 재설정 인증 코드 HTML 메일.
     * 상단 로고 영역은 비워 둠(추후 이미지 삽입). 인라인 스타일만 사용(메일 클라이언트 호환).
     */
    private String buildEmailHtml(String code) {
        return """
                <div style="margin:0;padding:24px;background:#f4f5f7;font-family:'Apple SD Gothic Neo',-apple-system,'Malgun Gothic',sans-serif;">
                  <div style="max-width:520px;margin:0 auto;background:#ffffff;border:1px solid #ececec;border-radius:14px;overflow:hidden;">
                    <!-- 로고 영역 (비워 둠 — 추후 로고 이미지 삽입) -->
                    <div style="height:64px;"></div>
                    <div style="border-top:2px solid #2b2b2b;"></div>
                    <div style="padding:36px 40px 40px;">
                      <h1 style="margin:0 0 24px;text-align:center;font-size:24px;font-weight:800;color:#1a1a1a;">비밀번호 재설정 인증 코드</h1>
                      <p style="margin:0 0 6px;text-align:center;font-size:14px;color:#555;line-height:1.6;">안녕하세요.</p>
                      <p style="margin:0 0 28px;text-align:center;font-size:14px;color:#555;line-height:1.6;">비밀번호 재설정을 위해 아래 인증 코드를 입력해 주세요.</p>
                      <div style="margin:0 auto 20px;background:#f3f4f6;border-radius:10px;padding:22px 0;text-align:center;">
                        <span style="font-size:34px;font-weight:800;letter-spacing:10px;color:#1a1a1a;">%s</span>
                      </div>
                      <p style="margin:0;text-align:center;font-size:13px;color:#9aa0a6;">이 코드는 %d분 이내에 입력해 주세요.</p>
                      <div style="margin:32px 0 0;border-top:1px solid #eee;"></div>
                      <p style="margin:18px 0 0;text-align:center;font-size:12px;color:#b0b4b8;line-height:1.6;">본인이 요청하지 않았다면 이 메일을 무시하셔도 됩니다.</p>
                    </div>
                  </div>
                </div>
                """.formatted(code, ttlMinutes);
    }
}
