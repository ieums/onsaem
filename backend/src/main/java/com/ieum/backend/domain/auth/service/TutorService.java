package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.dto.SettlementAccountRequest;
import com.ieum.backend.domain.auth.dto.SettlementAccountResponse;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.matching.service.MatchingNotificationService;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class TutorService {

    private final TutorRepository tutorRepository;
    private final MatchingApplicationRepository matchingApplicationRepository;
    private final MatchingNotificationService notificationService;

    public void updateAvailability(Long tutorId, boolean available) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));
        tutor.updateAvailability(available);

        List<MatchingApplication> pendingApps =
                matchingApplicationRepository.findByTutorIdAndStatus(tutorId, ApplicationStatus.PENDING);

        for (MatchingApplication app : pendingApps) {
            if (available) {
                notificationService.notifyTutorAvailable(app.getProblemId(), tutorId);
            } else {
                notificationService.notifyTutorUnavailable(app.getProblemId(), tutorId);
            }
        }
    }

    @Transactional(readOnly = true)
    public SettlementAccountResponse getSettlementAccount(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));
        return SettlementAccountResponse.from(tutor);
    }

    public SettlementAccountResponse updateSettlementAccount(Long tutorId, SettlementAccountRequest request) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));

        String bank = request.bank() == null ? null : request.bank().trim();
        String holder = request.holder() == null ? null : request.holder().trim();
        // 계좌번호는 하이픈/공백을 제거해 숫자만 저장한다.
        String account = request.account() == null ? null : request.account().replaceAll("[\\s-]", "");

        validateSettlementAccount(bank, account, holder);
        tutor.updateSettlementAccount(bank, account, holder);
        return SettlementAccountResponse.from(tutor);
    }

    /**
     * 정산 계좌 형식 검증 (자체 가능한 범위).
     * 예금주 '실명 확인'은 오픈뱅킹/PG 제휴가 필요해 여기서는 형식만 본다.
     */
    private void validateSettlementAccount(String bank, String account, String holder) {
        if (bank == null || bank.isBlank()) {
            throw BusinessException.badRequest("은행을 선택해 주세요.");
        }
        if (account == null || account.isBlank()) {
            throw BusinessException.badRequest("계좌번호를 입력해 주세요.");
        }
        if (!account.matches("\\d{8,20}")) {
            throw BusinessException.badRequest("계좌번호는 숫자 8~20자리로 입력해 주세요.");
        }
        if (holder == null || holder.isBlank()) {
            throw BusinessException.badRequest("예금주를 입력해 주세요.");
        }
        if (holder.length() > 20) {
            throw BusinessException.badRequest("예금주명이 너무 깁니다.");
        }
    }
}
