import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';

class TutorMyPageScreen extends StatelessWidget {
  const TutorMyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('마이페이지', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
