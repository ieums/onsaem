package com.ieum.backend.global.util;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

/**
 * 클래스패스 리소스(파일)를 String 으로 한 번에 읽어오는 유틸.
 * 프롬프트(.md), HTML 템플릿(.html) 등 텍스트 리소스 로딩에 사용.
 */
public final class ClasspathLoader {

    private ClasspathLoader() {
        // 유틸 클래스 — 인스턴스화 금지
    }

    /**
     * 클래스패스(예: {@code prompts/lesson-summary.html.md}) 위치의 파일을 UTF-8 문자열로 읽어 반환.
     * 보통 static final 상수 초기화 시점에 한 번만 호출해 메모리에 캐시.
     */
    public static String loadAsString(String classpathLocation) {
        try (InputStream in = ClasspathLoader.class
                .getClassLoader().getResourceAsStream(classpathLocation)) {
            Objects.requireNonNull(in, "리소스를 찾을 수 없음: " + classpathLocation);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("리소스 로드 실패: " + classpathLocation, e);
        }
    }
}