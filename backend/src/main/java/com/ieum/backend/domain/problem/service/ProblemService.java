package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.auth.entity.Role;
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
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.ConcurrencyFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
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
    private final PendingImageDeletions pendingImageDeletions;
    private final ProblemPersistence problemPersistence;
    private final com.ieum.backend.domain.lesson.repository.LessonRepository lessonRepository;

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
     * 분석 실패 시엔 committed=false로 두고 catch에서 저장한 이미지를 정리한다(삭제 누락 방지).
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public ProblemCreateResponse createProblem(List<MultipartFile> images,
                                               ProblemCreateRequest request,
                                               Long studentId) {
        // 0. 동시 등록 개수 제한 — OCR/이미지 저장 전에 먼저 막아 불필요한 비용을 줄인다.
        assertUnderActiveLimit(studentId);

        // 1. 이미지들 저장 (트랜잭션 밖)
        List<String> imageUrls = imageStorageService.storeAll(images);
        // 이미지가 Problem(저장) 또는 DetectionCache(선택 대기)에 묶였는지 여부.
        // true가 된 뒤의 예외에서는 catch가 이미지를 삭제하면 안 된다(유령 URL 방지).
        boolean committed = false;

        // 2~3. AI 분석 + 분기 처리. 실패하면 방금 저장한 이미지를 정리(삭제 누락 방지)
        try {
            AiAnalysisResult aiResult = geminiClient.analyze(images);
            List<AiAnalysisResult.DetectedProblem> detected = aiResult.getDetectedProblems();

            if (detected == null || detected.isEmpty()) {
                throw BusinessException.badRequest("이미지에서 문제를 감지하지 못했습니다.");
            }

            // 과목이 3종 이상 섞여 들어오면 OCR/분류 정확도가 급격히 떨어진다(지문·문제 매칭 혼선 등).
            // 자동 진행하지 말고 학생에게 다시 확인을 요청한다(한두 과목씩 나눠 업로드 유도).
            // (SINGLE_MULTIPAGE는 한 문제라 해당 없음)
            if (aiResult.getMode() != OcrResult.OcrMode.SINGLE_MULTIPAGE) {
                long distinctSubjects = detected.stream()
                        .map(AiAnalysisResult.DetectedProblem::getSubject)
                        .filter(s -> s != null && s != Subject.UNKNOWN)
                        .distinct()
                        .count();
                if (distinctSubjects >= 3) {
                    throw BusinessException.badRequest(
                            "서로 다른 과목이 3개 이상 감지됐어요. 정확한 분석을 위해 한 번에 한두 과목씩 나눠서 올려 주세요.");
                }
            }

            // (2) 한 문제 여러 장(SINGLE_MULTIPAGE) → suggestedOrder대로 이미지 재배치 후 단건 등록.
            //     pageTexts를 함께 보관해 이후 드래그 재정렬 시 재OCR 없이 텍스트만 재조합한다.
            if (aiResult.getMode() == OcrResult.OcrMode.SINGLE_MULTIPAGE) {
                List<String> orderedUrls = reorderByIndex(imageUrls, aiResult.getImageOrder());
                Problem problem = saveProblem(detected.get(0), orderedUrls, aiResult.getPageTexts(),
                        studentId, request.getSubject(), request.getStudentDescription());
                committed = true; // 저장 성공 → 이후 예외에도 이미지 보존
                return ProblemCreateResponse.from(problem, detected.get(0).isClassificationFailed());
            }

            // (a) 1개만 감지 → 자동 등록
            if (detected.size() == 1) {
                Problem problem = saveProblem(detected.get(0), imageUrls, List.of(),
                        studentId, request.getSubject(), request.getStudentDescription());
                committed = true; // 저장 성공 → 이후 예외에도 이미지 보존
                return ProblemCreateResponse.from(problem, detected.get(0).isClassificationFailed());
            }

            // (b) 여러 개 감지 → 결과를 업로드한 학생에게 묶어 캐시하고 detectionId 반환.
            //     선택은 /problems/select가 캐시에서 꺼내 저장(재OCR·재업로드 없음).
            //     (예전에는 선택 인덱스를 담아 다시 업로드하는 경로가 있었으나, 재OCR 결과가 1차와
            //      달라지면 인덱스가 다른 문제를 가리킬 수 있어 제거했다.)
            String detectionId = detectionCache.put(studentId, detected, imageUrls);
            committed = true; // 캐시에 보관(선택 대기) → 이후 예외에도 이미지 보존
            return ProblemCreateResponse.fromDetection(detected, imageUrls, detectionId);

        } catch (RuntimeException e) {
            // 저장(Problem)/캐시(선택 대기) 성공 이후의 예외라면 이미지가 실제로 묶여 있으므로
            // 절대 삭제하지 않는다 — 저장된 문제의 이미지를 지워 '유령 URL(404)'이 되는 버그 방지.
            // 저장/캐시 전(분석 실패·감지 0건·과목 혼합·짧은 글 등)일 때만 삭제되지 않은 이미지를 정리한다.
            if (!committed) {
                imageStorageService.deleteAll(imageUrls);
            }
            throw e;
        }
    }

    /**
     * 여러 문제 감지 후 학생이 하나를 선택해 확정 등록.
     * 1차 OCR 결과를 캐시에서 꺼내 쓰므로 재OCR/재업로드가 없다.
     *
     * - 트랜잭션 밖(NOT_SUPPORTED)에서 실행한다. 여기서 트랜잭션을 열면 ProblemPersistence가 그 트랜잭션에
     *   합류해 SERIALIZABLE 격리가 적용되지 않는다(격리 수준은 새 트랜잭션에만 적용됨).
     * - 캐시 항목은 take()로 꺼내는 순간 제거된다. 같은 detectionId로 동시에 두 번 들어와도 한 요청만 처리된다.
     *   저장이 실패하면 항목을 되돌려 학생이 다시 고를 수 있게 한다.
     */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public ProblemCreateResponse selectDetectedProblem(ProblemSelectRequest request, Long studentId) {
        String detectionId = request.getDetectionId();
        DetectionCache.Entry entry = detectionCache.take(detectionId);
        if (entry == null) {
            throw BusinessException.badRequest("문제 선택 시간이 만료됐거나 이미 등록된 선택이에요. 다시 업로드해 주세요.");
        }

        AiAnalysisResult.DetectedProblem chosen;
        List<String> kept;
        Problem problem;
        try {
            if (!entry.studentId().equals(studentId)) {
                throw BusinessException.forbidden("본인이 업로드한 문제만 선택할 수 있어요.");
            }
            int idx = request.getSelectedIndex();
            if (idx < 0 || idx >= entry.detected().size()) {
                throw BusinessException.badRequest("올바르지 않은 문제 인덱스입니다: " + idx);
            }
            // 다중 감지(선택) 경로는 항상 MULTI_PROBLEM이므로 pageTexts 없음.
            chosen = entry.detected().get(idx);
            kept = imagesToKeep(entry.imageUrls(), entry.detected(), idx);
            problem = saveProblem(chosen, kept, List.of(),
                    studentId, request.getSubject(), request.getStudentDescription());
        } catch (RuntimeException e) {
            detectionCache.restore(detectionId, entry); // 실패 → 다시 고를 수 있게 되돌림
            throw e;
        }

        scheduleUnkeptDeletion(entry.imageUrls(), kept);
        return ProblemCreateResponse.from(problem, chosen.isClassificationFailed());
    }

    /**
     * 선택한 문제에 붙여 저장할 이미지를 고른다(업로드 순서 유지).
     *
     * 모델이 매긴 장 번호(imageIndices)는 틀릴 수 있으므로, 지우는 쪽은 최대한 보수적으로 판단한다.
     * - 어느 문제든 범위 밖 인덱스가 있거나, 고른 문제의 인덱스가 비었거나, 업로드가 1장뿐이면 → 전부 유지.
     * - 그 외에는 "고른 문제의 장" + "어느 문제에도 배정되지 않은 장"을 유지하고,
     *   다른 문제에만 배정된 장만 제외한다(모델이 판단을 못 한 장까지 지워 원본을 잃지 않게).
     */
    private List<String> imagesToKeep(List<String> allUrls,
                                      List<AiAnalysisResult.DetectedProblem> detected,
                                      int chosenIdx) {
        List<Integer> chosenPages = detected.get(chosenIdx).getImageIndices();
        if (chosenPages == null || chosenPages.isEmpty() || allUrls.size() <= 1) {
            return allUrls;
        }
        Set<Integer> claimedByOthers = new HashSet<>();
        for (int i = 0; i < detected.size(); i++) {
            List<Integer> pages = detected.get(i).getImageIndices();
            if (pages == null) continue;
            for (Integer page : pages) {
                if (page == null || page < 0 || page >= allUrls.size()) {
                    return allUrls; // 장 번호를 신뢰할 수 없으면 전부 유지
                }
                if (i != chosenIdx) claimedByOthers.add(page);
            }
        }
        List<String> kept = new ArrayList<>();
        for (int page = 0; page < allUrls.size(); page++) {
            if (chosenPages.contains(page) || !claimedByOthers.contains(page)) {
                kept.add(allUrls.get(page));
            }
        }
        return kept;
    }

    /**
     * 선택되지 않은 다른 문제의 장은 즉시 지우지 않고 유예 삭제 목록에 넣는다.
     * 장 번호 판단이 틀렸을 때 운영자가 원본을 되살릴 시간을 남기기 위함이다(ProblemImageCleanupScheduler가 처리).
     */
    private void scheduleUnkeptDeletion(List<String> allUrls, List<String> kept) {
        List<String> others = allUrls.stream().filter(u -> !kept.contains(u)).toList();
        if (!others.isEmpty()) {
            pendingImageDeletions.schedule(others);
        }
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
                .pageTexts(pageTexts != null ? new ArrayList<>(pageTexts) : new ArrayList<>())
                .extractedText(dp.getExtractedText())
                .summary(dp.getSummary())
                .problemNumber(dp.getProblemNumber())
                .subject(subject)
                .primaryType(dp.getPrimaryType())
                .secondaryType(dp.getSecondaryType())
                .difficulty(dp.getDifficulty())
                .totalDifficultyScore(dp.getTotalDifficultyScore())
                .examType(dp.getExamType())
                .studentDescription(studentDescription)
                .build();

        // 등록 직전 개수 확인 + INSERT를 한 트랜잭션에서 원자적으로(동시 업로드 경합 방어).
        try {
            return problemPersistence.saveUnderActiveLimit(problem, studentId, MAX_ACTIVE_PROBLEMS);
        } catch (ConcurrencyFailureException e) {
            // SERIALIZABLE에서 같은 학생의 등록이 동시에 겹치면 DB가 한쪽을 교착/직렬화 실패로 끊는다.
            // 상한 초과가 아니라 '겹침'이므로 재시도를 안내한다.
            log.warn("문제 등록 동시성 충돌 studentId={}: {}", studentId, e.getMessage());
            throw BusinessException.conflict("같은 계정의 질문 등록이 동시에 처리되고 있어요. 잠시 후 다시 시도해 주세요.", e);
        }
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
     * 문제 단건 조회.
     * 학생은 본인 문제만 볼 수 있다. 강사는 매칭 과정에서 문제를 봐야 하므로 제한하지 않는다.
     */
    public ProblemDetailResponse getProblem(Long id, Long requesterId, Role requesterRole) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다: " + id));
        if (requesterRole == Role.STUDENT) {
            assertOwner(problem, requesterId);
        }
        return ProblemDetailResponse.from(problem);
    }

    /** 수정·취소 대상 문제를 조회하고, 요청한 학생의 문제인지 확인한다. */
    private Problem findOwnedProblem(Long id, Long studentId) {
        Problem problem = problemRepository.findById(id)
                .orElseThrow(() -> BusinessException.notFound("문제를 찾을 수 없습니다. id=" + id));
        assertOwner(problem, studentId);
        return problem;
    }

    private void assertOwner(Problem problem, Long studentId) {
        if (!problem.getStudentId().equals(studentId)) {
            throw BusinessException.forbidden("본인의 질문만 조회하거나 수정할 수 있어요.");
        }
    }

    /**
     * 분류 수정 (학생이 AI 분류 결과 수정)
     */
    @Transactional
    public ProblemDetailResponse updateClassification(Long id, ClassificationUpdateRequest request, Long studentId) {
        Problem problem = findOwnedProblem(id, studentId);

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
    public ProblemDetailResponse reorderPages(Long id, List<Integer> order, Long studentId) {
        Problem problem = findOwnedProblem(id, studentId);

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
        // 마이페이지 '내 질문'은 상태와 무관하게 전부 노출(매칭 대기/완료/만료/취소…) — 최신순.
        // 상태 키워드(칩)로 구분하므로 모든 상태를 그대로 보여준다.
        List<ApplicationStatus> countStatuses = List.of(ApplicationStatus.PENDING, ApplicationStatus.UNAVAILABLE);
        List<Problem> problems = problemRepository.findAllByStudentIdOrderByCreatedAtDesc(studentId);

        // 복습 진입용 problemId→lessonId 매핑(배치 1회, N+1 회피).
        java.util.Map<Long, Long> lessonIdByProblem = new java.util.HashMap<>();
        List<Long> problemIds = problems.stream().map(Problem::getId).toList();
        if (!problemIds.isEmpty()) {
            lessonRepository.findByProblemIdIn(problemIds).forEach(l -> {
                if (l.getProblemId() != null) {
                    // 한 문제에 강의가 여러 건이면 가장 최근(큰 id)을 사용.
                    lessonIdByProblem.merge(l.getProblemId(), l.getId(), Math::max);
                }
            });
        }

        return problems.stream()
                .map(problem -> {
                    int count = matchingApplicationRepository.countByProblemIdAndStatusIn(problem.getId(), countStatuses);
                    return StudentProblemResponse.from(
                            problem, count, lessonIdByProblem.get(problem.getId()));
                })
                .toList();
    }

    /**
     * 문제 취소
     */
    @Transactional
    public void cancelProblem(Long id, Long studentId) {
        Problem problem = findOwnedProblem(id, studentId);

        matchingApplicationRepository
                .findByProblemIdAndStatusIn(id, List.of(ApplicationStatus.PENDING))
                .forEach(app -> {
                    app.cancel();
                    notificationService.notifyProblemCancelled(id, app.getTutorId());
                });

        problem.cancel();

        // 모든 강사의 '새 질문 리스트'에서 즉시 사라지도록 브로드캐스트(미신청 강사 포함).
        notificationService.notifyProblemRemoved(id);

        // 즉시 삭제 — 취소된 문제 이미지는 더 이상 안 쓰이므로 정리(best-effort).
        // 취소(CANCELED) 질문은 학생 '내 질문' 목록(FE)에서 숨기므로 깨진 썸네일이 노출되지 않는다.
        imageStorageService.deleteAll(problem.getImageUrls());
    }
}