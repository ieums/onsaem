import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'routes/app_router.dart';

void main() {
  runApp(
    const ProviderScope(child: OnsaemApp()),
  );
}

class OnsaemApp extends StatelessWidget {
  const OnsaemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '온샘',
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
    );
  }
}
