/// PortOne(포트원) V2 실결제 설정.
///
/// 값은 PortOne 콘솔(https://admin.portone.io)에서 발급받아 채운다.
/// - [storeId]   : 콘솔 > 상점 정보 (store-XXXXXXXX-...)
/// - [channelKey]: 콘솔 > 연동 정보 > 채널 (channel-key-XXXXXXXX-...)
///                 테스트 채널이면 실제 돈이 빠지지 않는 '테스트 결제'가 된다.
/// - [appScheme] : 외부 결제앱(은행/카드앱)에서 우리 앱으로 복귀할 딥링크 스킴.
///                 네이티브 설정 필요(Android intent-filter / iOS CFBundleURLSchemes).
///
/// 셋이 비어있으면([isConfigured] == false) 결제 화면은 SDK를 띄우지 않고
/// 테스트 모드(백엔드 PORTONE_VERIFY=false와 짝)로 동작한다.
class PortoneConfig {
  PortoneConfig._();

  // PortOne 콘솔 값. 실결제 검증하려면 백엔드 PORTONE_VERIFY=true 필요.
  static const String storeId = 'store-ddabe359-8d0b-4f5b-a8d4-867316e9e581';
  static const String channelKey =
      'channel-key-d2fc7674-8028-4cda-afd0-d45b920483eb';

  /// 외부 결제앱 복귀용 딥링크 스킴. iOS Info.plist/Android에 이미 등록된 스킴을 재사용.
  static const String appScheme = 'com.ieum.ieum';

  /// 실결제 설정이 모두 채워졌는지. 플레이스홀더면 false → 테스트 모드.
  static bool get isConfigured =>
      !storeId.contains('...') && !channelKey.contains('...');
}
