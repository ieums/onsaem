import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/health_provider.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/server_health_dialog.dart';
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final navContext =
                appRouter.routerDelegate.navigatorKey.currentContext;
            if (navContext == null || !navContext.mounted) return;
            showServerHealthDialog(
              navContext,
              isSuccess: false,
              message: error.toString(),
            );
          });
        },
        loading: () {},
      );
    });

    ref.watch(healthProvider);

    return MaterialApp.router(
      title: '온샘',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
