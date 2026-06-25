package com.ieum.backend.domain.auth.service;

import com.ieum.backend.domain.auth.dto.TutorProfileResponse;
import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.StudentRepository;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.entity.MatchingApplication;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.matching.service.MatchingNotificationService;
import com.ieum.backend.domain.review.entity.Review;
import com.ieum.backend.domain.review.entity.enums.ReviewStatus;
import com.ieum.backend.domain.review.repository.ReviewRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class TutorService {

    private final TutorRepository tutorRepository;
    private final StudentRepository studentRepository;
    private final MatchingApplicationRepository matchingApplicationRepository;
    private final MatchingNotificationService notificationService;
    private final ReviewRepository reviewRepository;

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
    public TutorProfileResponse getProfile(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));

        List<Review> reviews = reviewRepository.findByTutorIdAndStatusOrderByCreatedAtDesc(
                tutorId, ReviewStatus.VISIBLE);

        Set<Long> studentIds = reviews.stream()
                .map(Review::getStudentId)
                .collect(Collectors.toSet());

        Map<Long, String> maskedNames = studentRepository.findAllById(studentIds).stream()
                .collect(Collectors.toMap(
                        s -> s.getId(),
                        s -> maskName(s.getName())));

        List<TutorProfileResponse.ReviewItem> reviewItems = reviews.stream()
                .map(r -> new TutorProfileResponse.ReviewItem(
                        r.getRating(),
                        r.getComment(),
                        r.getCreatedAt(),
                        maskedNames.getOrDefault(r.getStudentId(), "학생")))
                .toList();

        return new TutorProfileResponse(
                tutor.getId(),
                tutor.getName(),
                tutor.getProfileImageUrl(),
                tutor.getSchool(),
                tutor.getMajor(),
                tutor.getBio(),
                tutor.getSubjects(),
                tutor.getRatingAvg(),
                tutor.getReviewCount(),
                tutor.getLessonCount(),
                tutor.isAvailable(),
                reviewItems
        );
    }

    private String maskName(String name) {
        if (name == null || name.isBlank()) return "학생";
        if (name.length() == 1) return name;
        return name.charAt(0) + "*".repeat(name.length() - 1);
    }
}
