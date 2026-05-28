package com.ieum.backend.domain.payment.service;

import com.ieum.backend.domain.payment.dto.response.CoinBalanceResponse;
import com.ieum.backend.domain.payment.dto.response.CoinTransactionResponse;
import com.ieum.backend.domain.payment.entity.CoinTransaction;
import com.ieum.backend.domain.payment.entity.CoinWallet;
import com.ieum.backend.domain.payment.entity.enums.TransactionType;
import com.ieum.backend.domain.payment.repository.CoinTransactionRepository;
import com.ieum.backend.domain.payment.repository.CoinWalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CoinService {

    private final CoinWalletRepository walletRepository;
    private final CoinTransactionRepository transactionRepository;

    /**
     * 지갑 조회 (없으면 자동 생성)
     */
    @Transactional
    public CoinWallet getOrCreateWallet(Long studentId) {
        return walletRepository.findByStudentId(studentId)
                .orElseGet(() -> walletRepository.save(new CoinWallet(studentId)));
    }

    /**
     * 잔액 조회
     */
    public CoinBalanceResponse getBalance(Long studentId) {
        CoinWallet wallet = getOrCreateWallet(studentId);
        return CoinBalanceResponse.from(wallet);
    }

    /**
     * 코인 충전 (결제 완료 후 호출)
     */
    @Transactional
    public CoinBalanceResponse charge(Long studentId, int coinAmount, int bonusAmount, Long paymentId) {
        CoinWallet wallet = getOrCreateWallet(studentId);

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
        CoinWallet wallet = getOrCreateWallet(studentId);
        int bonus = 30;

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
        CoinWallet wallet = getOrCreateWallet(studentId);
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
        CoinWallet wallet = getOrCreateWallet(studentId);
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
        CoinWallet wallet = getOrCreateWallet(studentId);
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
        CoinWallet wallet = getOrCreateWallet(studentId);
        int cost = 3;

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
                .collect(Collectors.toList());
    }
}