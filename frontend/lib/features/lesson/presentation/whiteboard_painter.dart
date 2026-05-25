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
    // BlendMode.clear가 올바르게 동작하려면 항상 saveLayer로 격리해야 한다.
    // bounds=null: 현재 디바이스 clip(화면) 범위를 레이어 bounds로 사용.
    // Offset.zero & size([0,0,5000,5000]) 고정 시 캔버스 밖 스트로크가 클리핑되므로
    // null을 사용해 ClipPath가 허용하는 확장 영역까지 드로잉을 포함한다.
    canvas.saveLayer(null, Paint());

    final all = <DrawingStroke>[
      ...strokes,
      ?currentStroke,
      ?remoteStroke,
    ];

    for (final stroke in all) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        // 실제 픽셀을 지워 배경(이미지 또는 컨테이너 색)이 드러남
        paint.blendMode = BlendMode.clear;
      } else {
        paint.color = stroke.color;
      }

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

    canvas.restore();
  }

  @override
  bool shouldRepaint(WhiteboardPainter old) =>
      old.strokes != strokes ||
      old.currentStroke != currentStroke ||
      old.remoteStroke != remoteStroke;
}
