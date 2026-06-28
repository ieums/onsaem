package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.dto.LessonImageResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStartResponseDto;
import com.ieum.backend.domain.lesson.dto.RecordingStopResponseDto;
import com.ieum.backend.domain.lesson.dto.ExtendLessonResponse;
import com.ieum.backend.domain.lesson.dto.TokenRequestDto;
import com.ieum.backend.domain.lesson.dto.TokenResponseDto;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.entity.Lesson.LessonStatus;
import com.ieum.backend.domain.lesson.policy.LessonPolicy;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.report.entity.enums.ReportStatus;
import com.ieum.backend.domain.report.repository.ReportRepository;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import com.ieum.backend.global.agora.AgoraRecordingService;
import com.ieum.backend.global.agora.RtcTokenBuilder2;
import com.ieum.backend.global.config.AgoraConfig;
import com.ieum.backend.global.exception.BusinessException;
import com.ieum.backend.domain.lessonreview.service.LessonMediaStorage;
import com.ieum.backend.domain.problem.service.ImageStorageService;
import com.ieum.backend.global.s3.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class LessonService {

    private final AgoraConfig agoraConfig;
    private final LessonRepository lessonRepository;
    private final S3Service s3Service;
    private final AgoraRecordingService agoraRecordingService;
    private final CoinService coinService;
    private final LessonMediaStorage lessonMediaStorage;
    private final ImageStorageService imageStorageService; // local/S3 자동 분기 (강의 임시 이미지)
    private final SettlementRepository settlementRepository; // 정산 보류/확정 판단
    private final ReportRepository reportRepository;         // 신고 보류 게이팅
    private final TutorRepository tutorRepository;           // 등급 실적(완료 수업수) 반영
    private final LessonSettlementFinalizer settlementFinalizer; // 강의 1건 확정차감+정산(원자)

    @Transactional
    public Lesson createLesson(Long tutorId, Long studentId, String channelName) {
        return createLesson(tutorId, studentId, channelName, null);
    }

    @Transactional
    public Lesson createLesson(Long tutorId, Long studentId, String channelName, Long problemId) {
        // problemId가 안 넘어오면 채널명("problem-{id}")에서 유도 — 복습 PDF가 problem_id를 요구함.
        Long resolved = problemId != null ? problemId : parseProblemIdFromChannel(channelName);
        Lesson lesson = new Lesson(channelName, tutorId, studentId, resolved);
        return lessonRepository.save(lesson);
    }

    /** "problem-4" → 4. 형식이 아니면 null. */
    private Long parseProblemIdFromChannel(String channelName) {
        if (channelName == null || !channelName.startsWith("problem-")) return null;
        try {
            return Long.parseLong(channelName.substring("problem-".length()));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Agora 토큰 발급 (채널이 없으면 자동 생성)
     */
    @Transactional
    public TokenResponseDto generateToken(TokenRequestDto req) {
        Lesson lesson = lessonRepository.findByChannelName(req.getChannelName())
                .orElseGet(() -> lessonRepository.save(new Lesson(req.getChannelName())));
        // 채널명("problem-{id}")으로 강의가 만들어졌는데 problem_id가 비어 있으면 채워준다.
        // (복습 PDF가 problem_id로 문제 이미지를 찾으므로 — 누락 시 복습 자료가 안 생김)
        if (lesson.getProblemId() == null) {
            Long pid = parseProblemIdFromChannel(req.getChannelName());
            if (pid != null) lesson.assignProblem(pid);
        }

        RtcTokenBuilder2.Role role = "SUBSCRIBER".equalsIgnoreCase(req.getRole())
                ? RtcTokenBuilder2.Role.ROLE_SUBSCRIBER
                : RtcTokenBuilder2.Role.ROLE_PUBLISHER;

        int uid = 0;
        try {
            uid = Integer.parseInt(req.getUid());
        } catch (NumberFormatException ignored) {
        }

        int expireSeconds = agoraConfig.getTokenExpirySeconds();
        String token;
        try {
            token = new RtcTokenBuilder2().buildTokenWithUid(
                    agoraConfig.getAppId(),
                    agoraConfig.getAppCertificate(),
                    req.getChannelName(),
                    uid,
                    role,
                    expireSeconds,
                    expireSeconds
            );
        } catch (Exception e) {
            throw BusinessException.internalError("토큰 생성에 실패했습니다.");
        }

        long expireAt = System.currentTimeMillis() / 1000 + expireSeconds;
        return new TokenResponseDto(lesson.getId(), token, req.getChannelName(),
                agoraConfig.getAppId(), expireAt, lesson.getStudentId(), lesson.getTutorId());
    }

    /**
     * 수업 중 임시 이미지 S3 업로드 (최대 10장 제한)
     */
    @Transactional
    public LessonImageResponseDto uploadTempImage(Long lessonId, MultipartFile file) {
        Lesson lesson = findByIdOrThrow(lessonId);
        if (lesson.isImageLimitReached()) {
            throw BusinessException.badRequest("이미지는 최대 10장까지 업로드할 수 있습니다.");
        }
        // 문제 이미지와 동일하게 프로파일별 저장(local=디스크, prod=S3) → local에서 500 안 남.
        String imageUrl = imageStorageService.store(file);
        lesson.incrementImageCount();
        return new LessonImageResponseDto(imageUrl);
    }

    /**
     * 과금 강의 시작: 기본 30분 비용을 코인에서 hold하고 강의를 ACTIVE로.
     * 코인 부족 시 hold가 예외를 던져 시작이 막힌다(선불 보장).
     *
     * studentId·tutorId는 인증 도입 전까지 호출부가 전달한다(이후 SecurityContext로 교체).
     */
    @Transactional
    public void startLesson(Long lessonId, Long studentId, Long tutorId) {
        Lesson lesson = findByIdOrThrow(lessonId);

        // 재진입/중복 호출 시 이중 홀드 방지 — 이미 시작(과금)된 강의면 그대로 둔다.
        if (lesson.getStatus() == LessonStatus.ACTIVE || lesson.isBillable()) {
            return;
        }

        int cost = LessonPolicy.BASE_COST_COIN;
        coinService.hold(studentId, cost, lessonId);

        LocalDateTime endsAt = LocalDateTime.now().plusMinutes(LessonPolicy.BASE_DURATION_MIN);
        lesson.startBilling(studentId, tutorId, cost, endsAt);
    }

    /**
     * 강의 연장 (10/20/30분). 추가 코인을 hold하고 endsAt을 늘린다.
     * - 코인이 부족하면 hold하지 않고 부족액을 담아 반환 → 프론트가 충전 후 재호출(정지 없음).
     * - 최대 총 강의 시간(60분)을 넘기는 연장은 거부.
     */
    @Transactional
    public ExtendLessonResponse extendLesson(Long lessonId, Long studentId, int minutes) {
        Lesson lesson = findByIdOrThrow(lessonId);

        if (lesson.getStatus() != LessonStatus.ACTIVE || !lesson.isBillable()) {
            throw BusinessException.badRequest("진행 중인 강의만 연장할 수 있습니다.");
        }
        if (!studentId.equals(lesson.getStudentId())) {
            throw BusinessException.forbidden("본인 강의만 연장할 수 있습니다.");
        }

        int cost = LessonPolicy.extensionCost(minutes);  // 허용 단위(10/20/30) 검증 포함

        long currentMinutes = Duration.between(lesson.getStartedAt(), lesson.getEndsAt()).toMinutes();
        if (currentMinutes + minutes > LessonPolicy.MAX_DURATION_MIN) {
            throw BusinessException.badRequest(
                    "최대 강의 시간(" + LessonPolicy.MAX_DURATION_MIN + "분)을 초과합니다.");
        }

        // 잔액 부족 → hold 없이 부족액 반환 (충전 후 재시도)
        int available = coinService.getBalance(studentId).getAvailableBalance();
        if (available < cost) {
            return ExtendLessonResponse.needsPayment(lesson.getEndsAt(), cost, cost - available);
        }

        coinService.hold(studentId, cost, lessonId);
        lesson.extend(minutes, cost);
        return ExtendLessonResponse.extended(lesson.getEndsAt(), cost);
    }

    /**
     * 수업 완료: 상태 변경 + 임시 이미지 삭제 + (과금 강의면) 코인 확정 차감 + 강사 정산.
     *
     * 조기 종료여도 30분 고정 요금 전액 확정(무환불). 코인 확정과 정산 생성을
     * 같은 트랜잭션으로 묶어 정합성을 보장한다.
     * ACTIVE→COMPLETED 전이일 때만 과금 처리해 중복 완료 호출에 안전하다.
     */
    @Transactional
    public void completeLesson(Long lessonId, String recordingUrl) {
        Lesson lesson = findByIdOrThrow(lessonId);

        // ACTIVE→COMPLETED 전이일 때만 강사 완료 수업수에 반영(중복 완료 방어)
        boolean wasActive = lesson.getStatus() == LessonStatus.ACTIVE;

        lesson.complete(recordingUrl);  // recordingUrl null이면 기존 값 유지

        if (wasActive && lesson.getTutorId() != null) {
            tutorRepository.findById(lesson.getTutorId())
                    .ifPresent(Tutor::recordLessonCompleted);
        }

        // 녹음 URL이 비어 있으면 저장소가 주는 기본 참조로 채운다.
        // (로컬: marker → 전사 스케줄러가 인식 / prod: null → Agora가 세팅한 값 유지)
        if (lesson.getRecordingUrl() == null || lesson.getRecordingUrl().isBlank()) {
            String ref = lessonMediaStorage.defaultRecordingRef(lessonId);
            if (ref != null) {
                lesson.setRecordingUrl(ref);
            }
        }

        // 임시 이미지 정리는 best-effort — S3 실패(로컬 키 없음 등)가 수업 완료/정산을 막으면 안 된다.
        try {
            s3Service.deleteTempImages(lessonId);
        } catch (Exception e) {
            log.warn("[completeLesson] 임시 이미지 정리 실패(무시하고 완료 진행). lessonId={}, cause={}",
                    lessonId, e.getMessage());
        }

        // 정산은 즉시 하지 않고 24h 보류한다(완료 직후 신고가 들어오면 막아야 하므로).
        // 코인은 홀드 상태로 그대로 두고, finalizeDueSettlements() 스케줄러가
        // 24h 경과 + 미신고일 때 확정차감 + 정산한다.
    }

    /**
     * 보류된 정산 확정 — 스케줄러가 주기 호출.
     * 완료된 과금 강의 중 종료 24h 경과 + 정산 미생성 + (그 강의에) 열린 신고 없음 → 확정차감 + 정산.
     * 열린 신고가 있으면 건너뛴다(코인은 홀드 유지 → 운영자 처리 전까지 보류).
     */
    // 배치 자체는 트랜잭션으로 묶지 않는다(읽기 위주). 강의 1건의 확정차감+정산은
    // settlementFinalizer.finalizeOne(...)이 '건별 독립 트랜잭션'으로 처리하고, 여기선 건별 try/catch로
    // 한 건 실패가 나머지 강의 처리를 막지 않게 한다(다음 틱에 재시도됨).
    public void finalizeDueSettlements() {
        LocalDateTime cutoff = LocalDateTime.now().minusHours(24);
        List<Lesson> due = lessonRepository
                .findByStatusAndCoinCostIsNotNullAndEndedAtBefore(LessonStatus.COMPLETED, cutoff);
        for (Lesson lesson : due) {
            if (settlementRepository.findByLessonId(lesson.getId()).isPresent()) continue; // 이미 정산됨
            boolean blocked = reportRepository.existsByLessonIdAndStatusIn(
                    lesson.getId(), List.of(ReportStatus.PENDING, ReportStatus.REVIEWING));
            if (blocked) continue; // 신고 보류 — 정산 안 함(홀드 유지)

            try {
                settlementFinalizer.finalizeOne(lesson); // 확정차감 + 정산 (원자, 건별 트랜잭션)
            } catch (RuntimeException e) {
                // 이 강의만 건너뛰고 계속 — 다음 스케줄 틱에 재시도된다.
                log.warn("정산 확정 실패(다음 틱 재시도) lessonId={}: {}", lesson.getId(), e.getMessage());
            }
        }
    }

    /**
     * 강의 취소(불성립: 튜터 노쇼 등): 묶어둔 코인을 반환하고 CANCELED로.
     * ACTIVE 상태일 때만 hold 반환(중복 취소 방어).
     */
    @Transactional
    public void cancelLesson(Long lessonId) {
        Lesson lesson = findByIdOrThrow(lessonId);

        if (lesson.getStatus() == LessonStatus.ACTIVE && lesson.isBillable()) {
            coinService.releaseHold(lesson.getStudentId(), lesson.getCoinCost(), lessonId);
        }
        lesson.cancel();
    }

    /**
     * 녹화 시작: Lesson 상태를 ACTIVE로, Agora Cloud Recording 시작
     */
    @Transactional
    public RecordingStartResponseDto startRecording(Long lessonId) {
        Lesson lesson = findByIdOrThrow(lessonId);
        lesson.start();
        return agoraRecordingService.startRecording(lesson);
    }

    /**
     * 녹화 중지: Agora stop API 즉시 호출 후 200 반환.
     * S3 .m3u8 폴링은 비동기로 처리 — DB에 recordingUrl 저장은 백그라운드에서 완료.
     */
    @Transactional
    public RecordingStopResponseDto stopRecording(Long lessonId) {
        Lesson lesson = findByIdOrThrow(lessonId);
        RecordingStopResponseDto result = agoraRecordingService.stopRecording(lesson);
        agoraRecordingService.stopRecordingAsync(lessonId);
        return result;
    }

    // ──────────── private 헬퍼 ────────────

    private Lesson findByIdOrThrow(Long lessonId) {
        return lessonRepository.findById(lessonId)
                .orElseThrow(() -> BusinessException.notFound("수업을 찾을 수 없습니다."));
    }
}
