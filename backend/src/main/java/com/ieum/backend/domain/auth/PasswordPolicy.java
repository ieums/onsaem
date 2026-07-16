package com.ieum.backend.domain.auth;

/**
 * 비밀번호 정책(회원가입·비밀번호 재설정 공통).
 * 규칙: 8자 이상 + 영문 대문자 + 숫자 + 특수문자, 공백·한글 등 비허용 문자 불가.
 * (소문자는 허용하되 필수는 아님)
 */
public final class PasswordPolicy {

    /** 허용 특수문자 집합(정규식 char class 내부 표기). */
    private static final String SPECIAL = "!@#$%^&*()_+=\\[\\]{};:'\",.<>/?\\\\|`~-";

    /**
     * 8~64자, 영문 대문자/숫자/특수문자 각 1개 이상, 허용 문자(영문·숫자·특수)만.
     * char class에 공백·한글이 없으므로 자동으로 거부된다.
     */
    public static final String REGEX =
            "^(?=.*[A-Z])(?=.*\\d)(?=.*[" + SPECIAL + "])[A-Za-z\\d" + SPECIAL + "]{8,64}$";

    public static final String MESSAGE =
            "비밀번호는 8자 이상이며 영문 대문자·숫자·특수문자를 포함하고 공백·한글은 사용할 수 없어요.";

    private PasswordPolicy() {
    }
}
