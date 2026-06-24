package com.ieum.backend.domain.auth.service;

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
}
