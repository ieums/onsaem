package com.ieum.backend.domain.problem.entity;

import com.ieum.backend.domain.problem.entity.enums.Difficulty;
import com.ieum.backend.domain.problem.entity.enums.ExamType;
import com.ieum.backend.domain.problem.entity.enums.ProblemStatus;
import com.ieum.backend.domain.problem.entity.enums.Subject;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "problems")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Problem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long studentId;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "problem_images",
            joinColumns = @JoinColumn(name = "problem_id")
    )
    @Column(name = "image_url", length = 500)
    @OrderColumn(name = "page_order")
    private List<String> imageUrls = new ArrayList<>();

    /**
     * (2) 한 문제 여러 장(SINGLE_MULTIPAGE)일 때, imageUrls와 같은 순서의 장별 텍스트.
     * 드래그 재정렬 시 재OCR 없이 이 텍스트를 새 순서로 재조합해 extractedText를 갱신한다.
     * MULTI_PROBLEM(일반 등록)에서는 비어 있다 → 재정렬 미지원.
     */
    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "problem_page_texts",
            joinColumns = @JoinColumn(name = "problem_id")
    )
    @Column(name = "page_text", columnDefinition = "TEXT")
    @OrderColumn(name = "page_order")
    private List<String> pageTexts = new ArrayList<>();

    @Column(columnDefinition = "TEXT")
    private String extractedText;

    @Column(length = 500)
    private String summary;

    /** OCR이 인식한 문제 번호(01·02…). 한 이미지에 여러 문제일 때 강사에게 '몇 번' 표시용. 없으면 null. */
    private Integer problemNumber;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private Subject subject;

    @Column(length = 50)
    private String primaryType;

    @Column(length = 50)
    private String secondaryType;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private Difficulty difficulty;

    private Integer totalDifficultyScore;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private ExamType examType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ProblemStatus status;

    @Column(columnDefinition = "TEXT")
    private String studentDescription;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime resolvedAt;

    private LocalDateTime searchDeadline;

    @Column(nullable = false)
    private boolean searching = false;

    @Column(nullable = false)
    private boolean expiringSoonNotified = false;

    @Builder
    public Problem(Long studentId, List<String> imageUrls, List<String> pageTexts,
                   String extractedText,
                   String summary, Integer problemNumber, Subject subject, String primaryType,
                   String secondaryType, Difficulty difficulty,
                   Integer totalDifficultyScore, ExamType examType,
                   String studentDescription) {
        this.studentId = studentId;
        this.imageUrls = imageUrls != null ? imageUrls : new ArrayList<>();
        this.pageTexts = pageTexts != null ? pageTexts : new ArrayList<>();
        this.extractedText = extractedText;
        this.problemNumber = problemNumber;
        this.summary = summary;
        this.subject = subject;
        this.primaryType = primaryType;
        this.secondaryType = secondaryType;
        this.difficulty = difficulty;
        this.totalDifficultyScore = totalDifficultyScore;
        this.examType = examType;
        this.studentDescription = studentDescription;
        this.status = ProblemStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    // 학생이 분류 수정
    public void updateClassification(Subject subject, String primaryType,
                                     String secondaryType, Difficulty difficulty,
                                     ExamType examType) {
        if (subject != null) this.subject = subject;
        if (primaryType != null) this.primaryType = primaryType;
        if (secondaryType != null) this.secondaryType = secondaryType;
        if (difficulty != null) this.difficulty = difficulty;
        if (examType != null) this.examType = examType;
    }

    /**
     * (2) 여러 장 한 문제의 페이지 순서 재정렬.
     * newOrder는 현재 인덱스의 순열(예: [2,0,1]). imageUrls/pageTexts를 같은 순서로 재배치하고
     * extractedText를 새 순서의 pageTexts로 재조합한다(재OCR 없음).
     * 컬렉션 참조를 유지하려 in-place(clear+addAll)로 갱신한다.
     */
    public void reorderPages(List<Integer> newOrder) {
        List<String> reorderedImages = new ArrayList<>(newOrder.size());
        for (int idx : newOrder) {
            reorderedImages.add(imageUrls.get(idx));
        }
        imageUrls.clear();
        imageUrls.addAll(reorderedImages);

        // pageTexts가 이미지와 1:1로 있을 때(SINGLE_MULTIPAGE)만 같이 재배치 + 본문 재조합.
        // MULTI_PROBLEM의 여러 장짜리 한 문제는 pageTexts가 없으므로 이미지 순서만 바꾸고 본문은 그대로 둔다.
        if (pageTexts != null && pageTexts.size() == newOrder.size()) {
            List<String> reorderedPages = new ArrayList<>(newOrder.size());
            for (int idx : newOrder) {
                reorderedPages.add(pageTexts.get(idx));
            }
            pageTexts.clear();
            pageTexts.addAll(reorderedPages);
            this.extractedText = recomposeText(pageTexts);
        }
    }

    private static String recomposeText(List<String> pages) {
        StringBuilder sb = new StringBuilder();
        for (String t : pages) {
            if (t == null || t.isBlank()) continue;
            if (sb.length() > 0) sb.append("\n\n");
            sb.append(t.strip());
        }
        return sb.toString();
    }

    /** 이미지가 2장 이상이면 페이지(이미지) 순서 재정렬 가능.
     *  SINGLE_MULTIPAGE(지문 여러 장)뿐 아니라 MULTI_PROBLEM에서 한 문제가 여러 장에 걸친 경우도 포함. */
    public boolean isMultiPage() {
        return imageUrls != null && imageUrls.size() > 1;
    }

    // 문제 해결됨
    public void markResolved() {
        this.status = ProblemStatus.RESOLVED;
        this.resolvedAt = LocalDateTime.now();
    }

    // 문제 등록 취소
    public void cancel() {
        this.status = ProblemStatus.CANCELED;
        this.searching = false; // 탐색 종료 — 강사 '새 질문 리스트'(searching=true 조회)에서 빠지도록
    }

    public void startSearching(LocalDateTime deadline) {
        this.searching = true;
        this.searchDeadline = deadline;
    }

    public void extendDeadline(LocalDateTime newDeadline) {
        this.searchDeadline = newDeadline;
        this.searching = true;
        this.expiringSoonNotified = false;
    }

    public void markExpiringSoonNotified() {
        this.expiringSoonNotified = true;
    }

    public void matchTutor() {
        this.status = ProblemStatus.MATCHED;
        this.searching = false;
    }

    public void stopSearching() {
        this.searching = false;
    }

    /** 탐색 마감까지 강사 못 구함 → 만료 처리(상태 EXPIRED + 탐색 종료). */
    public void markExpired() {
        this.status = ProblemStatus.EXPIRED;
        this.searching = false;
    }

    /** 만료된 질문을 다시 탐색 대기로 되돌린다('다시 요청'). */
    public void reopen() {
        this.status = ProblemStatus.PENDING;
        this.expiringSoonNotified = false;
    }
}