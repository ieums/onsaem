import 'package:flutter/material.dart';
import 'package:ieum/features/student/widgets/classroom_drawing_surface.dart';

class ClassroomWhiteboard extends StatelessWidget {
  const ClassroomWhiteboard({
    super.key,
    this.frameBorderColor,
  });

  final Color? frameBorderColor;

  @override
  Widget build(BuildContext context) {
    return ClassroomDrawingSurface(
      frameBorderColor: frameBorderColor,
      emptyTitle: '화이트보드',
      emptySubtitle: '강사님과 함께 풀이를 작성해 보세요',
      emptyIcon: Icons.draw_rounded,
    );
  }
}
