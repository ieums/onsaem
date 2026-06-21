package com.ieum.backend.domain.lesson.service;

import com.ieum.backend.domain.lesson.dto.ExtendLessonResponse;
import com.ieum.backend.domain.lesson.entity.Lesson;
import com.ieum.backend.domain.lesson.entity.Lesson.LessonStatus;
import com.ieum.backend.domain.lesson.repository.LessonRepository;
import com.ieum.backend.domain.payment.entity.CoinWallet;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.CoinWalletRepository;
import com.ieum.backend.domain.payment.service.CoinService;
import com.ieum.backend.domain.settlement.entity.Settlement;
import com.ieum.backend.domain.settlement.repository.SettlementRepository;
import com.ieum.backend.global.exception.BusinessException;
import com.ieum.backend.global.s3.S3Service;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 강의 과금 ↔ 코인 ↔ 정산 연결(#8) 검증.
 *
 * v1 모델: 30분 고정 50코인. 시작 hold(50) → 완료 confirmDeduct(50) 전액 + 강사 정산.
 * 조기종료 무환불, 불성립(취소)만 releaseHold.
 */
@SpringBootTest
@ActiveProfiles({"local", "test"})
@DisplayName("강의 과금-정산 연결")
class LessonBillingTest {

    @Autowired LessonService lessonService;
    @Autowired LessonRepository lessonRepository;
    @Autowired CoinService coinService;
    @Autowired CoinWalletRepository walletRepository;
    @Autowired CoinTransactionRepository transactionRepository;
    @Autowired SettlementRepository settlementRepository;

    @MockBean S3Service s3Service;   // 임시 이미지 삭제(S3) 호출 무력화

    private static final long STUDENT_ID = 3100L;
    private static final long TUTOR_ID = 3200L;

    private Long lessonId;

    @BeforeEach
    void setUp() {
        settlementRepository.deleteAll();
        transactionRepository.deleteAll();
        walletRepository.deleteAll();
        lessonRepository.deleteAll();

        // 학생 지갑 100코인
        coinService.charge(STUDENT_ID, 100, 0, null);
        // 강의(채널) 생성
        this.lessonId = lessonRepository.save(new Lesson("ch-" + STUDENT_ID)).getId();
    }

    private CoinWallet wallet() {
        return walletRepository.findByStudentId(STUDENT_ID).orElseThrow();
    }

    @Test
    @DisplayName("시작 시 50코인 hold, 완료 시 전액 차감 + 강사 정산 생성")
    void startThenComplete() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);

        // hold: 가용만 차감(100→50), 총잔액은 유지
        assertThat(wallet().getAvailableBalance()).isEqualTo(50);
        assertThat(wallet().getBalance()).isEqualTo(100);

        lessonService.completeLesson(lessonId, null);

        // confirmDeduct: 총잔액도 50으로 확정
        assertThat(wallet().getBalance()).isEqualTo(50);
        assertThat(wallet().getAvailableBalance()).isEqualTo(50);

        // 강사 정산 1건: 50코인 → 플랫폼 20%(10) / 강사 80%(40) → 4,000원
        List<Settlement> settlements = settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID);
        assertThat(settlements).hasSize(1);
        assertThat(settlements.get(0).getTutorCoin()).isEqualTo(40);
        assertThat(settlements.get(0).getTutorAmount()).isEqualTo(4000);

        assertThat(lessonRepository.findById(lessonId).orElseThrow().getStatus())
                .isEqualTo(LessonStatus.COMPLETED);
    }

    @Test
    @DisplayName("조기 종료여도 30분 전액(50코인) 확정 — 별도 처리 없음")
    void earlyFinish_chargesFull() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);
        lessonService.completeLesson(lessonId, null);  // 바로 종료(조기)

        assertThat(wallet().getBalance()).isEqualTo(50);   // 전액 차감
        assertThat(settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID)).hasSize(1);
    }

    @Test
    @DisplayName("취소(불성립)는 묶어둔 코인을 전액 반환하고 정산하지 않는다")
    void cancel_releasesHold() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);
        lessonService.cancelLesson(lessonId);

        assertThat(wallet().getBalance()).isEqualTo(100);
        assertThat(wallet().getAvailableBalance()).isEqualTo(100);  // 반환됨
        assertThat(settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID)).isEmpty();
        assertThat(lessonRepository.findById(lessonId).orElseThrow().getStatus())
                .isEqualTo(LessonStatus.CANCELED);
    }

    @Test
    @DisplayName("완료를 두 번 호출해도 차감·정산은 한 번만 (멱등)")
    void completeTwice_isIdempotent() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);
        lessonService.completeLesson(lessonId, null);
        lessonService.completeLesson(lessonId, null);  // 재호출

        assertThat(wallet().getBalance()).isEqualTo(50);  // 100→50, 두 번 차감 아님
        assertThat(settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID)).hasSize(1);
    }

    @Test
    @DisplayName("코인이 부족하면 강의 시작이 막힌다(선불 보장)")
    void start_failsWhenInsufficientCoins() {
        long poorStudent = 3199L;
        coinService.charge(poorStudent, 30, 0, null);  // 30코인 < 50
        Long poorLesson = lessonRepository.save(new Lesson("ch-poor")).getId();

        assertThatThrownBy(() ->
                lessonService.startLesson(poorLesson, poorStudent, TUTOR_ID))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("연장(10분=20코인): 추가 hold + endsAt 증가, 완료 시 누적 70코인 차감·정산")
    void extend_holdsAndAccumulates() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);   // hold 50
        var before = lessonRepository.findById(lessonId).orElseThrow().getEndsAt();

        ExtendLessonResponse res = lessonService.extendLesson(lessonId, STUDENT_ID, 10);

        assertThat(res.extended()).isTrue();
        assertThat(res.requiredCoin()).isEqualTo(20);
        assertThat(res.endsAt()).isEqualTo(before.plusMinutes(10));
        // 가용: 100 - 50(기본) - 20(연장) = 30
        assertThat(wallet().getAvailableBalance()).isEqualTo(30);

        lessonService.completeLesson(lessonId, null);

        // 누적 70코인 확정 차감 (100→30)
        assertThat(wallet().getBalance()).isEqualTo(30);
        var s = settlementRepository.findByTutorIdOrderByCreatedAtDesc(TUTOR_ID);
        assertThat(s).hasSize(1);
        assertThat(s.get(0).getTotalCoin()).isEqualTo(70);   // 50 + 20
        assertThat(s.get(0).getTutorCoin()).isEqualTo(56);   // 70 * 0.8
    }

    @Test
    @DisplayName("연장 시 코인 부족하면 hold 없이 부족액을 반환한다(충전 후 재시도)")
    void extend_returnsShortfallWhenInsufficient() {
        // 잔액 60: 시작 hold 50 → 가용 10. 30분 연장(60코인) 시 50 부족
        long student = 3150L;
        coinService.charge(student, 60, 0, null);
        Long lesson = lessonRepository.save(new Lesson("ch-short")).getId();
        lessonService.startLesson(lesson, student, TUTOR_ID);

        ExtendLessonResponse res = lessonService.extendLesson(lesson, student, 30);

        assertThat(res.extended()).isFalse();
        assertThat(res.requiredCoin()).isEqualTo(60);
        assertThat(res.shortfallCoin()).isEqualTo(50);   // 60 필요 - 10 가용
        // hold 안 됨: 가용 그대로 10
        assertThat(walletRepository.findByStudentId(student).orElseThrow()
                .getAvailableBalance()).isEqualTo(10);
    }

    @Test
    @DisplayName("최대 강의 시간(60분)을 넘기는 연장은 거부된다")
    void extend_rejectsBeyondMax() {
        lessonService.startLesson(lessonId, STUDENT_ID, TUTOR_ID);  // 30분
        lessonService.extendLesson(lessonId, STUDENT_ID, 20);       // 50분

        // 50 + 20 = 70분 > 60분 → 거부
        assertThatThrownBy(() -> lessonService.extendLesson(lessonId, STUDENT_ID, 20))
                .isInstanceOf(BusinessException.class);
    }
}
