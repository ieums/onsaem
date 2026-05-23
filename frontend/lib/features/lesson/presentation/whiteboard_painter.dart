import 'package:flutter/material.dart';
import '../domain/lesson_model.dart';

class WhiteboardPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawingStroke? remoteStroke;

  const WhiteboardPainter({
    required this.strokes,
    this.currentStroke,
    this.remoteStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final all = <DrawingStroke>[
      ...strokes,
      ?currentStroke,
      ?remoteStroke,
    ];

    for (final stroke in all) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter old) =>
      old.strokes != strokes ||
      old.currentStroke != currentStroke ||
      old.remoteStroke != remoteStroke;
}
