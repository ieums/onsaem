import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

// API 기본 설정
final dio = Dio(BaseOptions(
  // 웹 테스트: http://localhost:8080/api/v1
  // 안드로이드 에뮬레이터: http://10.0.2.2:8080/api/v1
  // 실제 기기: http://[본인PC_IP]:8080/api/v1
  baseUrl: 'http://localhost:8080/api/v1', // 웹 테스트용(서버 열면 주소 수정)
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));

// 서버 연결 상태 Provider
final healthProvider = FutureProvider<String>((ref) async {
  final response = await dio.get('/health');
  return response.data.toString();
});

// 라우터 설정
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
  ],
);

void main() {
  runApp(
    const ProviderScope(
      child: IeumApp(),
    ),
  );
}

class IeumApp extends StatelessWidget {
  const IeumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '이음',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('이음')),
      body: Center(
        child: health.when(
          data: (message) => Text(
            '서버 연결 상태: $message',
            style: const TextStyle(fontSize: 18),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(
            '서버 연결 실패: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}