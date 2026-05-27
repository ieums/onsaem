import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/health_provider.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/routes/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OnsaemApp(),
    ),
  );
}

class OnsaemApp extends ConsumerStatefulWidget {
  const OnsaemApp({super.key});

  @override
  ConsumerState<OnsaemApp> createState() => _OnsaemAppState();
}

class _OnsaemAppState extends ConsumerState<OnsaemApp> {
  bool _healthCheckHandled = false;

  @override
  void initState() {
    super.initState();
    // 온보딩 첫 화면 이후에 health 체크 (시작 직후 팝업/깜빡임 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) ref.read(healthProvider.future);
      });
    });
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
