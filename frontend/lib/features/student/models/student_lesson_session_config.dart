/// 수업 세션·알림 타이밍 설정
abstract final class StudentLessonSessionConfig {
  /// 기본 과외 연결 시간
  static const sessionDuration = Duration(minutes: 30);

  /// 종료 전 연장 안내 시점 (종료 5분 전)
  static const extensionNoticeBeforeEnd = Duration(minutes: 5);

  /// 테스트 확인용 압축 타이머. 실서비스에서는 false.
  static const useDemoTimers = false;

  static const demoMatchDelay = Duration(seconds: 10);
  static const demoSubjectExpertDelay = Duration(seconds: 30);
  static const demoConnectionDelay = Duration(seconds: 3);
  static const demoExtensionDelay = Duration(seconds: 20);
}
