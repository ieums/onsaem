package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.auth.entity.Tutor;
import com.ieum.backend.domain.auth.repository.TutorRepository;
import com.ieum.backend.domain.matching.entity.ApplicationStatus;
import com.ieum.backend.domain.matching.repository.MatchingApplicationRepository;
import com.ieum.backend.domain.matching.service.MatchingNotificationService;
import com.ieum.backend.domain.problem.dto.internal.AiAnalysisResult;
import com.ieum.backend.domain.problem.dto.internal.OcrResult;
import com.ieum.backend.domain.problem.dto.request.ClassificationUpdateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemCreateRequest;
import com.ieum.backend.domain.problem.dto.request.ProblemSelectRequest;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import com.ieum.backend.domain.problem.dto.response.ProblemCreateResponse;
import com.ieum.backend.domain.problem.dto.response.ProblemDetailResponse;
import com.ieum.backend.domain.problem.dto.response.SearchingProblemResponse;
import com.ieum.backend.domain.problem.dto.response.StudentProblemResponse;
import com.ieum.backend.domain.problem.entity.Problem;
import com.ieum.backend.domain.problem.repository.ProblemRepository;
import com.ieum.backend.global.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProblemService {

    private final ProblemRepository problemRepository;
    private final TutorRepository tutorRepository;
    private final MatchingApplicationRepository matchingApplicationRepository;
    private final MatchingNotificationService notificationService;
    private final ImageStorageService imageStorageService;
    private final GeminiClient geminiClient;
    private final DetectionCache detectionCache;

    /** 학생 1명이 동시에 등록(탐색 중)할 수 있는 질문 수 상한. */
    private static final int MAX_ACTIVE_PROBLEMS = 3;

    /** 문제로 인정할 최소 텍스트 길이(글 없는/빈 이미지 차단용). */
    private static final int MIN_PROBLEM_TEXT_LEN = 10;

    /**
     * 문제 등록 (이미지 1~N장)
     *
     * 이미지 저장 + 수 초 걸리는 Gemini 호출은 DB 트랜잭션 밖에서 수행한다(NOT_SUPPORTED).
     * 트랜잭션은 실제 INSERT 시점(saveProblem → repository.save)에만 짧게 열려,
     * 외부 호출이 DB 커넥션을 오래 점유하지 않는다.
     *
     * TODO: AI 분석이 실패하면 이미 저장된 이미지가 고아로 남는다.
     *       ImageStorageService에 delete를 추가해 실패 시 정리 필요(별도 작업).
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public ProblemCreateResponse createProblem(List<MultipartFile> images,
                                               ProblemCreateRequest request) {
        // 0. 동시 등록 개수 제한 — OCR/이미지 저장 전에 먼저 막아 불필요한 비용을 줄인다.
        assertUnderActiveLimit(request.getStudentId());

        // 1. 이미지들 저장 (트랜잭션 밖)
        List<String> imageUrls = imageStorageService.storeAll(images);

        // 2~3. AI 분석 + 분기 처리. 실패하면 방금 저장한 이미지를 정리(고아 방지)
        try {
            AiAnalysisResult aiResult = geminiClient.analyze(images);
            List<AiAnalysisResult.DetectedProblem> detected = aiResult.getDetectedProblems();

            if (detected == null || detected.isEmpty()) {
                throw BusinessException.badRequest("이미지에서 문제를 감지하지 못했습니다.");
            }

            // (2) 한 문제 여러 장(SINGLE_MULTIPAGE) → suggestedOrder대로 이미지 재배치 후 단건 등록.
            //     pageTexts를 함께 보관해 이후 드래그 재정렬 시 재OCR 없이 텍스트만 재조합한다.
            if (aiResult.getMode() == OcrResult.OcrMode.SINGLE_MULTIPAGE) {
                List<String> orderedUrls = reorderByIndex(imageUrls, aiResult.getImageOrder());
                Problem problem = saveProblem(detected.get(0), orderedUrls, aiResult.getPageTexts(),
                        request.getStudentId(), request.getSubject(), request.getStudentDescription());
                return ProblemCreateResponse.from(problem, detected.get(0).isClassificationFailed());
            }

            Integer selectedIndex = request.getSelectedProblemIndex();

            // (a) 1개만 감지 → 자동 등록
            if (detected.size() == 1) {
                Problem problem = saveProblem(detected.get(0), imageUrls, List.of(),
                        request.getStudentId(), request.getSubject(), request.getStudentDescription());
                return ProblemCreateResponse.from(problem, detected.get(0).isClassificationFailed());
            }

            // (b) 여러 개 감지 + 학생이 선택함(레거시 경로) → 선택한 것만 등록
            if (selectedIndex != null) {
                if (selectedIndex < 0 || selectedIndex >= detected.size()) {
                    throw BusinessException.badRequest("올바르지 않은 문제 인덱스입니다: " + selectedIndex);
                }
                Problem problem = saveProblem(detected.get(selectedIndex), imageUrls, List.of(),
                        request.getStudentId(), request.getSubject(), request.getStudentDescription());
                return ProblemCreateResponse.from(problem, detected.get(selectedIndex).isClassificationFailed());
            }

            // (c) 여러 개 감지 + 선택 안 함 → 결과를 캐시하고 detectionId 반환.
            //     선택은 /problems/select가 캐시에서 꺼내 저장(재OCR·재업로드 없음).
            String detectionId = detectionCache.put(detected, imageUrls);
            return ProblemCreateResponse.fromDetection(detected, imageUrls, detectionId);

        } catch (RuntimeException e) {
            // 단, 선택 대기(캐시에 올린 경우)는 이미지가 살아있어야 하므로 정리하지 않는다.
            imageStorageService.deleteAll(imageUrls);
            throw e;
        }
    }

    /**
     * 여러 문제 감지 후 학생이 하나를 선택해 확정 등록.
     * 1차 OCR 결과를 캐시에서 꺼내 쓰므로 재OCR/재업로드가 없다.
     */
    @Transactional
    public ProblemCreateResponse selectDetectedProblem(ProblemSelectRequest request) {
        DetectionCache.Entry entry = detectionCache.get(request.getDetectionId());
        if (entry == null) {
            throw BusinessException.badRequest("문제 선택 시간이 만료됐어요. 다시 업로드해 주세요.");
        }
        int idx = request.getSelectedIndex();
        if (idx < 0 || idx >= entry.detected().size()) {
            throw BusinessException.badRequest("올바르지 않은 문제 인덱스입니다: " + idx);
        }

        // 다중 감지(선택) 경로는 항상 MULTI_PROBLEM이므로 pageTexts 없음.
        Problem problem = saveProblem(entry.detected().get(idx), entry.imageUrls(), List.of(),
                request.getStudentId(), request.getSubject(), request.getStudentDescription());
        detectionCache.remove(request.getDetectionId());
        return ProblemCreateResponse.from(problem, entry.detected().get(idx).isClassificationFailed());
    }

    /**
     * imageOrder(이미지 인덱스 순열)대로 imageUrls를 재배치. 순열이 비었거나 크기가 안 맞으면 원본 그대로.
     */
    private List<String> reorderByIndex(List<String> imageUrls, List<Integer> order) {
        if (order == null || order.size() != imageUrls.size()) {
            return imageUrls;
        }
        List<String> reordered = new java.util.ArrayList<>(order.size());
        for (int idx : order) {
            if (idx < 0 || idx >= imageUrls.size()) return imageUrls; // 방어
            reordered.add(imageUrls.get(idx));
        }
        return reordered;
    }

    /**
     * Problem 저장 (공통 로직). 과목은 학생 선택값 우선(없으면 AI 판정).
     * pageTexts는 SINGLE_MULTIPAGE에서만 채워지며(재정렬용 보관), 그 외엔 빈 리스트.
     */
    private Problem saveProblem(AiAnalysisResult.DetectedProblem dp, List<String> imageUrls,
                                List<String> pageTexts,
                                Long studentId, Subject chosenSubject, String studentDescription) {
        // 실제 등록 직전 재확인(선택 경로 포함, 동시 등록 경합 방어).
        assertUnderActiveLimit(studentId);

        // (3) 글 없는/너무 짧은 이미지 차단 — OCR이 의미 있는 문제 글을 못 뽑았으면 등록 거부.
        String text = dp.getExtractedText() == null ? "" : dp.getExtractedText().strip();
        if (text.length() < MIN_PROBLEM_TEXT_LEN) {
            throw BusinessException.badRequest(
                    "이미지에서 문제 글을 충분히 찾지 못했어요. 문제가 잘 보이게 다시 올려주세요.");
        }

        // (4) 언어 휴리스틱 보정 — 본문이 영문 압도적이면 ENGLISH (국어 오인식 방지).
        Subject aiSubject = languageAdjustedSubject(text, dp.getSubject());

        // (5) 과목 결정 — 학생 선택을 존중하되 AI/휴리스틱과 불일치하면 수정화면으로 유도(완전 의존 X).
        Subject subject;
        if (chosenSubject != null) {
            subject = chosenSubject;
            if (aiSubject != null && aiSubject != Subject.UNKNOWN && aiSubject != chosenSubject) {
                dp.setClassificationFailed(true); // needsClassification=true → 분류 수정화면
            }
        } else {
            subject = aiSubject != null ? aiSubject : Subject.UNKNOWN;
        }

        Problem problem = Problem.builder()
                .studentId(studentId)
                .imageUrls(imageUrls)
                .pageTexts(pageTexts != null ? new java.util.ArrayList<>(pageTexts) : new java.util.ArrayList<>())
                .extractedText(dp.getExtractedText())
                .summary(dp.getSummary())
                .subject(subject)
                .primaryType(dp.getPrimaryType())
                .secondaryType(dp.getSecondaryType())
                .difficulty(dp.getDifficulty())
                .totalDifficultyScore(dp.getTotalDifficultyScore())
                .examType(dp.getExamType())
                .studentDescription(studentDescription)
                .build();

        return problemRepository.save(problem);
    }

    /**
     * (4) 언어 휴리스틱 — 본문이 영문 압도적이면 ENGLISH로 보정.
     * 국어 지문에 영단어 몇 개 섞인 정도로는 안 바뀌게 라틴 비율을 높게(≈80%) 잡는다.
     */
    private Subject languageAdjustedSubject(String text, Subject aiSubject) {
        int hangul = 0, latin = 0;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c >= '가' && c <= '힣') hangul++;
            else if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) latin++;
        }
        if ((hangul + latin) >= 20 && latin >= hangul * 4) {
            return Subject.ENGLISH;
        }
        return aiSubject;
    }

    /** 탐색 중(매칭 대기) 질문이 상한 이상이면 등록을 막는다. */
    private void assertUnderActiveLimit(Long studentId) {
        long active = problemRepository.countByStudentIdAndStatus(studentId, ProblemStatus.PENDING);
        if (active >= MAX_ACTIVE_PROBLEMS) {
            throw BusinessException.conflict(
                    "동시에 등록할 수 있는 질문은 최대 " + MAX_ACTIVE_PROBLEMS
                            + "개예요. 기존 질문을 마치거나 취소한 뒤 다시 시도해 주세요.");
        }
    }

    /**
     * 문제 단건 조회
     */
    public ProblemDetailResponse getProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다: " + id));
        return ProblemDetailResponse.from(problem);
    }

    /**
     * 분류 수정 (학생이 AI 분류 결과 수정)
     */
    @Transactional
    public ProblemDetailResponse updateClassification(Long id, ClassificationUpdateRequest request) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));

        problem.updateClassification(
                request.getSubject(),
                request.getPrimaryType(),
                request.getSecondaryType(),
                request.getDifficulty(),
                request.getExamType()
        );

        return ProblemDetailResponse.from(problem);
    }

    /**
     * (2) 여러 장 한 문제의 페이지 순서 재정렬 (드래그 결과 반영).
     * order는 현재 인덱스의 순열(예: [2,0,1]). 보관된 pageTexts를 새 순서로 재조합 → extractedText 갱신(재OCR 없음).
     */
    @Transactional
    public ProblemDetailResponse reorderPages(Long id, List<Integer> order) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));

        if (!problem.isMultiPage()) {
            throw BusinessException.badRequest("페이지 순서 변경은 여러 장으로 등록된 한 문제만 가능해요.");
        }
        validatePermutation(order, problem.getImageUrls().size());

        problem.reorderPages(order);
        return ProblemDetailResponse.from(problem);
    }

    /** order가 0..n-1을 정확히 한 번씩 담은 순열인지 검증. */
    private void validatePermutation(List<Integer> order, int n) {
        if (order == null || order.size() != n) {
            throw BusinessException.badRequest("순서 정보가 올바르지 않아요.");
        }
        boolean[] seen = new boolean[n];
        for (Integer idx : order) {
            if (idx == null || idx < 0 || idx >= n || seen[idx]) {
                throw BusinessException.badRequest("순서 정보가 올바르지 않아요.");
            }
            seen[idx] = true;
        }
    }

    /**
     * 강사 탐색 중인 문제 목록 조회
     */
    public List<SearchingProblemResponse> getSearchingProblems(Long tutorId) {
        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> BusinessException.notFound("강사를 찾을 수 없습니다."));

        List<Subject> subjects = tutor.getSubjects().stream()
                .map(Subject::fromAny)
                .filter(s -> s != null && s != Subject.UNKNOWN)
                .toList();

        if (subjects.isEmpty()) {
            return List.of();
        }

        List<Problem> problems = problemRepository.findAllSearchingBySubjects(LocalDateTime.now(), subjects);
        return problems.stream()
                .map(p -> SearchingProblemResponse.from(p,
                        matchingApplicationRepository.existsByProblemIdAndTutorId(p.getId(), tutorId)))
                .toList();
    }

    /**
     * 학생 문제 목록 조회
     */
    public List<StudentProblemResponse> getStudentProblems(Long studentId) {
        List<ApplicationStatus> countStatuses = List.of(ApplicationStatus.PENDING, ApplicationStatus.UNAVAILABLE);
        return problemRepository.findAllByStudentIdAndStatus(studentId, ProblemStatus.PENDING).stream()
                .map(problem -> {
                    int count = matchingApplicationRepository.countByProblemIdAndStatusIn(problem.getId(), countStatuses);
                    return StudentProblemResponse.from(problem, count);
                })
                .toList();
    }

    /**
     * 문제 취소
     */
    @Transactional
    public void cancelProblem(Long id) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));

        matchingApplicationRepository
                .findByProblemIdAndStatusIn(id, List.of(ApplicationStatus.PENDING))
                .forEach(app -> {
                    app.cancel();
                    notificationService.notifyProblemCancelled(id, app.getTutorId());
                });

        problem.cancel();

        // 모든 강사의 '새 질문 리스트'에서 즉시 사라지도록 브로드캐스트(미신청 강사 포함).
        notificationService.notifyProblemRemoved(id);

        // (1)A 즉시 삭제 — 취소된 문제 이미지는 더 이상 안 쓰이므로 정리(best-effort).
        // 취소 문제는 학생 목록(PENDING만)에도 안 보이므로 안전.
        imageStorageService.deleteAll(problem.getImageUrls());
    }
}