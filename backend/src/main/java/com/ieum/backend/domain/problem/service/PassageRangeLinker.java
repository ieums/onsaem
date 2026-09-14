package com.ieum.backend.domain.problem.service;

import com.ieum.backend.domain.problem.dto.internal.OcrResult.DetectedText;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 지문 묶음 연결 — "[14~17] 다음 글을 읽고 물음에 답하시오." 같은 범위 표기로 지문을 공유하는 문제들을 잇는다.
 *
 * OCR 모델은 긴 지문을 묶음의 첫 문제(14번)에만 한 번 넣고, 나머지 문제(15~17번)는 문제 번호부터 시작하는 경우가 많다.
 * 그대로 두면 16번을 골랐을 때 지문 텍스트도, 지문이 있는 장도 함께 저장되지 않는다.
 * 모델이 지문을 반복해 주길 기대하지 않고, 서버가 범위 표기와 문제 번호를 보고 직접 붙인다.
 *
 * - 지문 텍스트: 범위 표기부터 첫 문제 번호("14.") 직전까지를 잘라, 지문이 없는 같은 묶음 문제 앞에 붙인다.
 * - 지문 장: 범위 표기가 들어 있던 문제의 장 번호를 같은 묶음 문제의 imageIndices에 더한다.
 */
final class PassageRangeLinker {

    /** [14~17] · [01~03] · [1-3] 형태의 범위 표기 */
    private static final Pattern RANGE = Pattern.compile("\\[\\s*(\\d{1,3})\\s*[~∼～\\-–]\\s*(\\d{1,3})\\s*]");

    /** 묶음 하나에 들어갈 수 있는 최대 문제 수(잘못 읽은 숫자를 범위로 오인하지 않기 위한 상한) */
    private static final int MAX_GROUP_SIZE = 10;

    /** 이미 지문을 포함했는지 비교할 때 쓰는 지문 앞부분 길이(공백 제외) */
    private static final int HEAD_LEN = 40;

    private PassageRangeLinker() {
    }

    private record Group(int from, int to, String passage, List<Integer> pages) {
        boolean contains(Integer number) {
            return number != null && number >= from && number <= to;
        }
    }

    static void apply(List<DetectedText> texts) {
        Map<String, Group> groups = new LinkedHashMap<>();
        for (DetectedText owner : texts) {
            String text = owner.getExtractedText();
            if (text == null) continue;
            Matcher m = RANGE.matcher(text);
            if (!m.find()) continue;

            int from = Integer.parseInt(m.group(1));
            int to = Integer.parseInt(m.group(2));
            if (from >= to || to - from + 1 > MAX_GROUP_SIZE) continue;

            String key = from + "-" + to;
            if (groups.containsKey(key)) continue; // 같은 묶음은 처음 찾은 문제를 기준으로

            groups.put(key, new Group(from, to, cutPassage(text, m.start(), from, owner.getProblemNumber()),
                    owner.getImageIndices() == null ? List.of() : List.copyOf(owner.getImageIndices())));
        }

        for (Group g : groups.values()) {
            for (DetectedText member : texts) {
                if (!g.contains(member.getProblemNumber())) continue;
                attachPassageText(member, g.passage());
                attachPassagePages(member, g.pages());
            }
        }
    }

    /**
     * 범위 표기 위치부터 묶음 첫 문제 번호("14." 또는 "01.") 직전까지를 지문으로 자른다.
     * 첫 문제 번호를 찾지 못하면 어디까지가 지문인지 알 수 없으므로 null(텍스트는 붙이지 않고 장만 연결).
     */
    private static String cutPassage(String text, int rangeStart, int from, Integer ownerNumber) {
        int stemNumber = ownerNumber != null ? ownerNumber : from;
        Pattern stem = Pattern.compile("(?m)^\\s*0*" + stemNumber + "\\s*[.．]");
        Matcher s = stem.matcher(text);
        int searchFrom = text.indexOf(']', rangeStart) + 1;
        if (!s.find(Math.max(searchFrom, 0))) {
            return null;
        }
        String passage = text.substring(rangeStart, s.start()).strip();
        return passage.isEmpty() ? null : passage;
    }

    private static void attachPassageText(DetectedText member, String passage) {
        if (passage == null) return;
        String body = member.getExtractedText() == null ? "" : member.getExtractedText();
        String head = compact(passage);
        head = head.substring(0, Math.min(HEAD_LEN, head.length()));
        if (compact(body).contains(head)) return; // 이미 지문을 갖고 있음
        member.setExtractedText(passage + "\n\n" + body.strip());
    }

    private static void attachPassagePages(DetectedText member, List<Integer> pages) {
        if (pages.isEmpty()) return;
        List<Integer> merged = new ArrayList<>(member.getImageIndices() == null ? List.of() : member.getImageIndices());
        for (Integer page : pages) {
            if (page != null && !merged.contains(page)) merged.add(page);
        }
        Collections.sort(merged); // 업로드 순서대로
        member.setImageIndices(merged);
    }

    private static String compact(String s) {
        return s.replaceAll("\\s+", "");
    }
}
