package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.CoinTransactionResponse;
import com.ieum.backend.domain.payment.entity.CoinTransaction;
import com.ieum.backend.domain.payment.entity.CoinWallet;
import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import com.ieum.backend.domain.payment.policy.PaymentPolicy;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.CoinWalletRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CoinService {

    private final CoinWalletRepository walletRepository;
    private final CoinTransactionRepository transactionRepository;

    /**
     * 관리자 수동 코인 지급 (보상·환불 등). BONUS 트랜잭션으로 적립하며 사유를 설명으로 남긴다.
     */
    @Transactional
    public CoinBalanceResponse grantByAdmin(Long studentId, int amount, String reason) {
        if (amount <= 0) {
            throw BusinessException.badRequest("지급 코인은 1 이상이어야 합니다.");
        }
        CoinWallet wallet = getWalletForUpdate(studentId);
        wallet.charge(amount);
        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.BONUS)
                .amount(amount)
                .balanceAfter(wallet.getBalance())
                .description(reason != null && !reason.isBlank()
                        ? reason.trim()
                        : "관리자 지급")
                .build());
        return CoinBalanceResponse.from(wallet);
    }

    /**
     * 지갑 조회 (없으면 자동 생성)
     */
    @Transactional
    public CoinWallet getOrCreateWallet(Long studentId) {
        return walletRepository.findByStudentId(studentId)
                .orElseGet(() -> walletRepository.save(new CoinWallet(studentId)));
    }

    /**
     * 잔액을 변경하는 연산용 지갑 조회 — 행에 쓰기 락을 걸어 동시 변경을 직렬화.
     * 지갑이 없으면 생성(첫 거래). studentId UNIQUE 제약이 생성 race를 막는다.
     */
    @Transactional
    public CoinWallet getWalletForUpdate(Long studentId) {
        return walletRepository.findByStudentIdForUpdate(studentId)
                .orElseGet(() -> walletRepository.save(new CoinWallet(studentId)));
    }

    /**
     * 잔액 조회 — 읽기 전용. 지갑이 아직 없으면(충전 이력 없음) 잔액 0으로 응답한다.
     * (조회 API에서 지갑을 생성하면 readOnly 트랜잭션에서 쓰기가 발생해 실패한다.)
     */
    public CoinBalanceResponse getBalance(Long studentId) {
        return walletRepository.findByStudentId(studentId)
                .map(CoinBalanceResponse::from)
                .orElseGet(() -> CoinBalanceResponse.builder()
                        .studentId(studentId)
                        .balance(0)
                        .availableBalance(0)
                        .build());
    }

    /**
     * 코인 충전 (결제 완료 후 호출)
     */
    @Transactional
    public CoinBalanceResponse charge(Long studentId, int coinAmount, int bonusAmount, Long paymentId) {
        CoinWallet wallet = getWalletForUpdate(studentId);

        // 기본 코인 충전
        wallet.charge(coinAmount);
        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.CHARGE)
                .amount(coinAmount)
                .balanceAfter(wallet.getBalance())
                .paymentId(paymentId)
                .description(coinAmount + "코인 충전")
                .build());

        // 보너스 코인
        if (bonusAmount > 0) {
            wallet.charge(bonusAmount);
            transactionRepository.save(CoinTransaction.builder()
                    .studentId(studentId)
                    .type(TransactionType.BONUS)
                    .amount(bonusAmount)
                    .balanceAfter(wallet.getBalance())
                    .paymentId(paymentId)
                    .description("충전 보너스 " + bonusAmount + "코인")
                    .build());
        }

        return CoinBalanceResponse.from(wallet);
    }

    /**
     * 가입 보너스 (30코인)
     */
    @Transactional
    public CoinBalanceResponse giveSignupBonus(Long studentId) {
        CoinWallet wallet = getWalletForUpdate(studentId);
        int bonus = PaymentPolicy.SIGNUP_BONUS_COIN;

        wallet.charge(bonus);
        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.SIGNUP_BONUS)
                .amount(bonus)
                .balanceAfter(wallet.getBalance())
                .description("가입 축하 보너스 " + bonus + "코인")
                .build());

        return CoinBalanceResponse.from(wallet);
    }

    /**
     * 코인 홀드 (강의 시작 시)
     */
    @Transactional
    public void hold(Long studentId, int amount, Long lessonId) {
        CoinWallet wallet = getWalletForUpdate(studentId);
        wallet.hold(amount);

        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.HOLD)
                .amount(-amount)
                .balanceAfter(wallet.getBalance())
                .lessonId(lessonId)
                .description("강의 시작 " + amount + "코인 홀드")
                .build());
    }

    /**
     * 홀드 확정 (강의 종료 시)
     */
    @Transactional
    public void confirmDeduct(Long studentId, int amount, Long lessonId) {
        CoinWallet wallet = getWalletForUpdate(studentId);
        wallet.confirmDeduct(amount);

        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.DEDUCT)
                .amount(-amount)
                .balanceAfter(wallet.getBalance())
                .lessonId(lessonId)
                .description("강의 완료 " + amount + "코인 차감 확정")
                .build());
    }

    /**
     * 홀드 해제 (강의 취소 시)
     */
    @Transactional
    public void releaseHold(Long studentId, int amount, Long lessonId) {
        CoinWallet wallet = getWalletForUpdate(studentId);
        wallet.releaseHold(amount);

        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.RELEASE)
                .amount(amount)
                .balanceAfter(wallet.getBalance())
                .lessonId(lessonId)
                .description("강의 취소 " + amount + "코인 반환")
                .build());
    }

    /**
     * AI 튜터 사용 (즉시 차감)
     */
    @Transactional
    public CoinBalanceResponse useForAi(Long studentId) {
        CoinWallet wallet = getWalletForUpdate(studentId);
        int cost = PaymentPolicy.AI_USE_COST_COIN;

        wallet.useForAi(cost);
        transactionRepository.save(CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.AI_USE)
                .amount(-cost)
                .balanceAfter(wallet.getBalance())
                .description("AI 튜터 사용 " + cost + "코인")
                .build());

        return CoinBalanceResponse.from(wallet);
    }

    /**
     * 거래 내역 조회
     */
    public List<CoinTransactionResponse> getTransactions(Long studentId) {
        return transactionRepository.findByStudentIdOrderByCreatedAtDesc(studentId)
                .stream()
                .map(CoinTransactionResponse::from)
                .toList();
    }
    /**
     * 코인 환불 처리
     * - 잔액에서 코인 차감
     * - REFUND 트랜잭션 기록
     *
     * @param studentId  학생 ID
     * @param coinAmount 환불할 코인 (충전 + 보너스 합산)
     * @param paymentId  원본 Payment ID (트랜잭션 추적용)
     */
    @Transactional
    public CoinBalanceResponse refund(Long studentId, Integer coinAmount, Long paymentId) {
        CoinWallet wallet = getWalletForUpdate(studentId);

        // 잔액 부족 체크
        if (wallet.getBalance() < coinAmount) {
            throw BusinessException.badRequest("환불 불가: 잔액 부족. 현재 잔액 " + wallet.getBalance() + " < 환불 요청 " + coinAmount);
        }

        // 잔액 차감
        wallet.subtract(coinAmount);

        // 환불 트랜잭션 기록
        CoinTransaction tx = CoinTransaction.builder()
                .studentId(studentId)
                .type(TransactionType.REFUND)
                .amount(-coinAmount)
                .balanceAfter(wallet.getBalance())
                .description("결제 환불 (paymentId: " + paymentId + ")")
                .paymentId(paymentId)
                .build();
        transactionRepository.save(tx);

        return CoinBalanceResponse.from(wallet);
    }

}