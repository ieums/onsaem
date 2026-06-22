import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/student/widgets/classroom_drawing_surface.dart';

class ClassroomProblemView extends StatelessWidget {
  const ClassroomProblemView({
    super.key,
    required this.summary,
    this.imageBytes,
    this.frameBorderColor,
  });

  final String summary;
  final Uint8List? imageBytes;
  final Color? frameBorderColor;

  @override
  Widget build(BuildContext context) {
    return ClassroomDrawingSurface(
      frameBorderColor: frameBorderColor,
      emptyTitle: '문제',
      emptySubtitle: '문제 위에 풀이를 작성해 보세요',
      emptyIcon: Icons.quiz_rounded,
      background: ColoredBox(
        color: Colors.white,
        child: imageBytes != null
            ? Image.memory(
                imageBytes!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: AppColors.shellOnSurfaceLight,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
