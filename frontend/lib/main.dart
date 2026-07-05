import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/network/health_provider.dart';
import 'package:ieum/core/providers/app_lifecycle_provider.dart';
import 'package:ieum/core/providers/onboarding_seen_provider.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/auth/data/auth_controller.dart'; 
import 'package:ieum/routes/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 소셜 로그인 SDK 초기화. 웹에선 dart:io(Platform)·네이티브 SDK가 없어 예외가 날 수 있으므로
  // 가드 + try/catch로 감싸 앱 자체 기동이 막히지 않게 한다.
  try {
    KakaoSdk.init(nativeAppKey: '8e025998483a2799ea1ebf2efd15288e');
  } catch (e) {
    debugPrint('[Onsaem] KakaoSdk 초기화 실패: $e');
  }
  try {
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb
          ? '630470477380-cgn6t5ff9q6ok15ccqtudce1b9elv4b5.apps.googleusercontent.com'
          : (Platform.isIOS
              ? '630470477380-7p64mea0fvnj1nk5o1d66ic32kv8p20t.apps.googleusercontent.com'
              : null),
      serverClientId:
          '630470477380-8tfmb9f6d8iaaj4rc0gkgri1gaqao5sj.apps.googleusercontent.com',
    );
  } catch (e) {
    debugPrint('[Onsaem] GoogleSignIn 초기화 실패: $e');
  }
  } catch (e) {
    debugPrint('[Onsaem] GoogleSignIn 초기화 실패: $e');
  }
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
  try {
    await AppNotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('[Onsaem] 알림 초기화 실패: $error');
    debugPrint('$stackTrace');
  }

  // 저장된 토큰이 있으면 로그인 상태 복원 (토큰 없으면 즉시 통과)
  final container = ProviderContainer();
  try {
    await container.read(authControllerProvider).restoreSession();
  } catch (_) {}

  // 온보딩 "봤음" 플래그를 미리 로드(redirect 가 동기로 읽을 수 있게).
  await loadOnboardingSeen(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OnsaemApp(),
    ),
  );
}

class OnsaemApp extends ConsumerStatefulWidget {
  const OnsaemApp({super.key});

  @override
  ConsumerState<OnsaemApp> createState() => _OnsaemAppState();
}

class _OnsaemAppState extends ConsumerState<OnsaemApp>
    with WidgetsBindingObserver {
  bool _healthCheckHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) ref.read(healthProvider.future);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String>>(healthProvider, (previous, next) {
      if (_healthCheckHandled) return;
      next.when(
        data: (message) {
          _healthCheckHandled = true;
          debugPrint('[Onsaem] 서버 연결 성공: $message');
        },
        error: (error, _) {
          _healthCheckHandled = true;
          debugPrint('[Onsaem] 서버 연결 실패: $error');
        },
        loading: () {},
      );
    });

    return MaterialApp.router(
      title: '온샘',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
