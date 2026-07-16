import 'package:flutter/material.dart';

/// 비밀번호 규칙 1개 — 라벨 + 충족 여부 판정.
class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule(this.label, this.test);
}

/// 회원가입·비밀번호 재설정 공통 규칙.
/// (백엔드 PasswordPolicy.REGEX 와 동일한 조건)
final List<PasswordRule> kPasswordRules = [
  PasswordRule('8자 이상', (v) => v.length >= 8),
  PasswordRule('영문 대문자 포함 (A-Z)', (v) => RegExp(r'[A-Z]').hasMatch(v)),
  PasswordRule('숫자 포함 (0-9)', (v) => RegExp(r'[0-9]').hasMatch(v)),
  PasswordRule(
    '특수문자 포함 (!@#\$ 등)',
    (v) => RegExp(r'''[!@#$%^&*()_+=\[\]{};:'",.<>/?\\|`~-]''').hasMatch(v),
  ),
  // 공백·한글(자모/완성형) 등 비허용 문자가 없어야 함
  PasswordRule(
    '공백·한글 사용 안 함',
    (v) => v.isNotEmpty && !RegExp(r'[\sㄱ-ㆎ가-힣]').hasMatch(v),
  ),
];

/// 회원가입용 축약 표시 규칙(3줄). 공백·한글 같은 기본 규칙은 숨기되 [passwordSatisfiesAll]로 계속 강제한다.
final List<PasswordRule> kPasswordRulesCompact = [
  PasswordRule('8자 이상', (v) => v.length >= 8),
  PasswordRule(
    '영문 대문자·숫자 포함',
    (v) => RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v),
  ),
  PasswordRule(
    '특수문자 포함 (!@#\$ 등)',
    (v) => RegExp(r'''[!@#$%^&*()_+=\[\]{};:'",.<>/?\\|`~-]''').hasMatch(v),
  ),
];

/// 모든 규칙 충족 여부.
bool passwordSatisfiesAll(String v) => kPasswordRules.every((r) => r.test(v));

/// 충족하지 못한 첫 규칙의 안내 문구(숨긴 규칙 위반도 명확히 알려주기 위함). 모두 충족 시 null.
String? passwordError(String v) {
  for (final r in kPasswordRules) {
    if (!r.test(v)) return '비밀번호: ${r.label} 조건을 확인해 주세요.';
  }
  return null;
}

/// 입력값에 맞춰 규칙마다 ✓가 켜지는 실시간 체크리스트.
/// [accent]는 충족 시 색(기본 초록). 배경 따라 [unmetColor] 지정 가능.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({
    super.key,
    required this.password,
    this.accent = const Color(0xFF2E9E6B),
    this.unmetColor = const Color(0xFF9AA0A6),
    this.compact = false,
  });

  final String password;
  final Color accent;
  final Color unmetColor;

  /// true면 회원가입용 축약(3줄·작은 글씨). false면 전체 5줄.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rules = compact ? kPasswordRulesCompact : kPasswordRules;
    final fontSize = compact ? 11.0 : 12.5;
    final iconSize = compact ? 14.0 : 16.0;
    final gap = compact ? 1.5 : 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules)
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap),
            child: Builder(builder: (_) {
              final met = rule.test(password);
              final color = met ? accent : unmetColor;
              return Row(
                children: [
                  Icon(
                    met
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: iconSize,
                    color: color,
                  ),
                  SizedBox(width: compact ? 6 : 7),
                  Text(
                    rule.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: color,
                      fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}
