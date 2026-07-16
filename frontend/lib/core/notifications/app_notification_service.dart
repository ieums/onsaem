import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

const androidNotificationChannelId = 'onsaem_student_alerts';
const _inAppAlertSoundAsset = 'sounds/alert_ding.wav';

final appNotificationServiceProvider = Provider<AppNotificationService>(
  (ref) => AppNotificationService.instance,
);

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _alertPlayer = AudioPlayer();

  bool _initialized = false;
  bool _audioReady = false;

  bool get supportsOsNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static NotificationDetails bannerDetails({bool soundOnlyOnIos = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        androidNotificationChannelId,
        '온샘 알림',
        channelDescription: '매칭, AI 튜터, 수업 시간 연장 알림',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.message,
        // 배너 우측에 앱 로고 썸네일 표시(밋밋함 완화). #6 런처 아이콘 적용 시 로고로 바뀜.
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: !soundOnlyOnIos,
        presentBadge: !soundOnlyOnIos,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: !soundOnlyOnIos,
        presentBadge: !soundOnlyOnIos,
        presentSound: true,
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!supportsOsNotifications) {
      debugPrint(
        '[Onsaem] OS 알림 미지원 플랫폼: $defaultTargetPlatform (iOS/Android/macOS에서 테스트)',
      );
      _initialized = true;
      await _prepareAlertPlayer();
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        androidNotificationChannelId,
        '온샘 알림',
        description: '매칭, AI 튜터, 수업 시간 연장 알림',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
    debugPrint('[Onsaem] 알림 서비스 초기화 완료 ($defaultTargetPlatform)');

    await _prepareAlertPlayer();
  }

  Future<void> _prepareAlertPlayer() async {
    if (_audioReady) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _alertPlayer.setReleaseMode(ReleaseMode.stop);
      await _alertPlayer.setVolume(1);
      _audioReady = true;
    } catch (error, stackTrace) {
      debugPrint('[Onsaem] 알림음 플레이어 준비 실패: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<bool> _ensureReady({required String reason}) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (error, stackTrace) {
        debugPrint('[Onsaem] 알림 lazy 초기화 실패($reason): $error');
        debugPrint('$stackTrace');
        return false;
      }
    }

    if (!supportsOsNotifications) {
      debugPrint(
        '[Onsaem] 알림 스킵($reason): 미지원 플랫폼 $defaultTargetPlatform',
      );
      return false;
    }

    if (!_initialized) {
      debugPrint('[Onsaem] 알림 스킵($reason): 초기화 실패');
      return false;
    }

    return true;
  }

  int notificationIdForKey(String key) => key.hashCode.abs() % 100000;

  Future<bool> hasPermission() async {
    if (!await _ensureReady(reason: '권한 확인')) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      if (options != null) {
        return options.isEnabled ||
            options.isProvisionalEnabled ||
            options.isAlertEnabled ||
            options.isSoundEnabled;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final options = await macos?.checkPermissions();
      if (options != null) {
        return options.isEnabled ||
            options.isAlertEnabled ||
            options.isSoundEnabled;
      }
    }

    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    if (!await _ensureReady(reason: '권한 요청')) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final granted = await macos?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final requested = await android?.requestNotificationsPermission();
      if (requested == true) return true;

      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return false;
  }

  Future<bool> ensurePermission() async {
    if (!await _ensureReady(reason: '권한 확보')) return false;
    if (await hasPermission()) return true;
    return requestPermission();
  }

  Future<void> openSystemSettings() => openAppSettings();

  Future<void> playInAppAlertSound() async {
    await HapticFeedback.heavyImpact();
    await _prepareAlertPlayer();

    if (_audioReady) {
      try {
        await _alertPlayer.stop();
        await _alertPlayer.play(AssetSource(_inAppAlertSoundAsset));
        return;
      } catch (error, stackTrace) {
        debugPrint('[Onsaem] 앱 내 알림음 재생 실패: $error');
        debugPrint('$stackTrace');
      }
    }

    if (await _ensureReady(reason: '앱 내 알림음') &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) &&
        await hasPermission()) {
      try {
        await _plugin.show(
          DateTime.now().millisecondsSinceEpoch % 100000,
          ' ',
          ' ',
          bannerDetails(soundOnlyOnIos: true),
        );
        return;
      } catch (error, stackTrace) {
        debugPrint('[Onsaem] Darwin 알림 사운드 fallback 실패: $error');
        debugPrint('$stackTrace');
      }
    }

    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> cancelScheduled(String dedupeKey) async {
    if (!await _ensureReady(reason: '예약 취소')) return;
    await _plugin.cancel(notificationIdForKey(dedupeKey));
  }

  Future<bool> scheduleBanner({
    required String dedupeKey,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (!await _ensureReady(reason: dedupeKey)) return false;
    if (!await hasPermission()) {
      debugPrint('[Onsaem] 알림 예약 스킵: OS 알림 권한 없음 ($dedupeKey)');
      return false;
    }

    final id = notificationIdForKey(dedupeKey);
    await _plugin.cancel(id);

    try {
      if (delay <= Duration.zero) {
        await _plugin.show(id, title, body, bannerDetails());
        return true;
      }

      final scheduledAt = tz.TZDateTime.now(tz.local).add(delay);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        bannerDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
        '[Onsaem] 알림 예약 완료: $dedupeKey → ${scheduledAt.toIso8601String()}',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[Onsaem] 예약 알림 실패($dedupeKey): $error');
      debugPrint('$stackTrace');
      try {
        await _plugin.show(id, title, body, bannerDetails());
        return true;
      } catch (fallbackError) {
        debugPrint('[Onsaem] 즉시 알림 fallback 실패: $fallbackError');
        return false;
      }
    }
  }

  Future<bool> showBanner({
    required String dedupeKey,
    required String title,
    required String body,
  }) async {
    if (!await _ensureReady(reason: dedupeKey)) return false;
    if (!await hasPermission()) return false;

    try {
      await _plugin.show(
        notificationIdForKey(dedupeKey),
        title,
        body,
        bannerDetails(),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[Onsaem] 알림 표시 실패: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
