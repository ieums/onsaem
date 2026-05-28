import 'package:flutter/material.dart';
import 'package:ieum/features/student/widgets/student_tab_placeholder_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentTabPlaceholderScreen(tabTitle: '홈');
  }
}
