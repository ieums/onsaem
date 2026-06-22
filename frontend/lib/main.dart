import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/network/health_provider.dart';
import 'package:ieum/core/providers/app_lifecycle_provider.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/auth/data/auth_controller.dart'; 
import 'package:ieum/routes/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
