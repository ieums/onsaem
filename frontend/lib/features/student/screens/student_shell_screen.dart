import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 학생 홈 (추후 탭·화면 확장)
class StudentShellScreen extends StatelessWidget {
  const StudentShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('온샘'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: const Center(
        child: Text(
          '학생 홈 (준비 중)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
