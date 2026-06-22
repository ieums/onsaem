import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notificationPromptedKey = 'notification_permission_prompted';

/// 온보딩(스플래시) 화면 — 로고 영역 제외, 이미지와 동일한 텍스트 레이아웃
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _goToLogin);
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    await _requestNotificationPermissionIfNeeded();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_notificationPromptedKey) == true) return;

      await AppNotificationService.instance.requestPermission();
      await prefs.setBool(_notificationPromptedKey, true);
    } catch (error, stackTrace) {
      debugPrint('[Onsaem] 알림 권한 요청 실패: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _goToLogin,
        behavior: HitTestBehavior.opaque,
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 120),
                  Text(
                    '온샘',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D26),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '모르면 바로, 지금 바로',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1D26),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '실시간 1:1 온라인 과외',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5B6475),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
