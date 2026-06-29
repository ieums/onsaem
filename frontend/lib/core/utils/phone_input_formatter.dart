import 'package:flutter/services.dart';

/// 휴대폰 번호 자동 하이픈 포맷터 (010-1234-5678).
/// 숫자만 추출 → 3·7번째 뒤에 '-' → 최대 11자리. 회원가입·프로필 수정 공통.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue; // 11자리 초과 입력 차단
    final formatted = formatPhoneNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 하이픈 유무가 섞인 번호를 010-1234-5678 형태로 정규화한다. (초기 로드값 표시용)
/// 숫자만 추출 후 최대 11자리로 자르고 3·7번째 뒤에 하이픈을 넣어, 이미 하이픈이
/// 있어도 이중 하이픈이 생기지 않는다. 빈 문자열은 그대로 빈 문자열.
String formatPhoneNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final d = digits.length > 11 ? digits.substring(0, 11) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 3 || i == 7) buffer.write('-');
    buffer.write(d[i]);
  }
  return buffer.toString();
}
