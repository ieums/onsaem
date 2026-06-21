import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';

class _ConceptChartStyle {
  const _ConceptChartStyle({
    required this.surfaceColor,
    required this.gridColor,
    required this.axisColor,
    required this.labelColor,
  });

  final Color surfaceColor;
  final Color gridColor;
  final Color axisColor;
  final Color labelColor;

  factory _ConceptChartStyle.of(ShellTheme shell, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ConceptChartStyle(
      surfaceColor: isDark ? shell.detailBackground : Colors.white,
      gridColor: shell.cardBorder.withValues(alpha: isDark ? 0.55 : 0.85),
      axisColor: shell.hintColor.withValues(alpha: 0.45),
      labelColor: shell.hintColor,
    );
  }
}

class StudentReviewConceptGraphCard extends StatelessWidget {
  const StudentReviewConceptGraphCard({
    super.key,
    required this.graph,
    required this.shell,
  });

  final StudentReviewConceptGraph graph;
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    final chartStyle = _ConceptChartStyle.of(shell, context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.75)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.insights_rounded,
                    size: 20,
                    color: shell.subtitleColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    graph.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: chartStyle.surfaceColor,
                  border: Border.all(
                    color: shell.cardBorder.withValues(alpha: 0.65),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: graph.type == StudentReviewConceptGraphType.comparison
                      ? 160
                      : 176,
                  width: double.infinity,
                  child: switch (graph.type) {
                    StudentReviewConceptGraphType.line => CustomPaint(
                        painter: _LineConceptGraphPainter(
                          segments: graph.lineSegments,
                          labels: graph.axisLabels,
                          style: chartStyle,
                        ),
                      ),
                    StudentReviewConceptGraphType.bar => CustomPaint(
                        painter: _BarConceptGraphPainter(
                          bars: graph.barItems,
                          style: chartStyle,
                        ),
                      ),
                    StudentReviewConceptGraphType.comparison => SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _ComparisonGraph(
                            items: graph.comparisonItems,
                            shell: shell,
                          ),
                        ),
                      ),
                  },
                ),
              ),
            ),
          ),
          if (graph.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                graph.caption,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: shell.subtitleColor,
                ),
              ),
            ),
          ],
          if (graph.legend.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in graph.legend)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: shell.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ComparisonGraph extends StatelessWidget {
  const _ComparisonGraph({
    required this.items,
    required this.shell,
  });

  final List<StudentReviewComparisonItem> items;
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: shell.detailBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: shell.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: items[i].accentColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        items[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: shell.titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final bullet in items[i].bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: shell.hintColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bullet,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: shell.subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LineConceptGraphPainter extends CustomPainter {
  _LineConceptGraphPainter({
    required this.segments,
    required this.labels,
    required this.style,
  });

  final List<StudentReviewGraphSegment> segments;
  final List<String> labels;
  final _ConceptChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 32.0;
    const padRight = 16.0;
    const padTop = 20.0;
    const padBottom = 32.0;

    final plotWidth = size.width - padLeft - padRight;
    final plotHeight = size.height - padTop - padBottom;
    final origin = Offset(padLeft, size.height - padBottom);

    for (var i = 1; i <= 3; i++) {
      final y = origin.dy - plotHeight * (i / 4);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        Paint()
          ..color = style.gridColor
          ..strokeWidth = 1,
      );
    }

    final axisPaint = Paint()
      ..color = style.axisColor
      ..strokeWidth = 1.2;
    canvas.drawLine(
      origin,
      Offset(size.width - padRight, origin.dy),
      axisPaint,
    );
    canvas.drawLine(origin, Offset(origin.dx, padTop), axisPaint);

    final totalLength =
        segments.fold<double>(0, (sum, segment) => sum + segment.length);
    var startX = 0.0;

    for (final segment in segments) {
      final segmentWidth = plotWidth * (segment.length / totalLength);
      final path = Path();
      const steps = 28;

      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = padLeft + startX + segmentWidth * t;
        final yNorm = _segmentY(segment.startY, segment.endY, t);
        final y = origin.dy - yNorm * plotHeight;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      if (segment.fill) {
        final fillPath = Path.from(path)
          ..lineTo(padLeft + startX + segmentWidth, origin.dy)
          ..lineTo(padLeft + startX, origin.dy)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = segment.color.withValues(alpha: 0.14)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = segment.color
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      startX += segmentWidth;
    }

    if (labels.length > 1) {
      for (var i = 0; i < labels.length; i++) {
        final x = padLeft + plotWidth * (i / (labels.length - 1));
        final painter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: style.labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 40);
        painter.paint(
          canvas,
          Offset(x - painter.width / 2, size.height - padBottom + 8),
        );
      }
    }
  }

  double _segmentY(double start, double end, double t) {
    return start + (end - start) * (0.5 - 0.5 * math.cos(math.pi * t));
  }

  @override
  bool shouldRepaint(covariant _LineConceptGraphPainter oldDelegate) {
    return segments != oldDelegate.segments || style != oldDelegate.style;
  }
}

class _BarConceptGraphPainter extends CustomPainter {
  _BarConceptGraphPainter({
    required this.bars,
    required this.style,
  });

  final List<StudentReviewBarItem> bars;
  final _ConceptChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 20.0;
    const padRight = 20.0;
    const padTop = 24.0;
    const padBottom = 36.0;

    final plotHeight = size.height - padTop - padBottom;
    final gap = 14.0;
    final barWidth =
        (size.width - padLeft - padRight - (bars.length - 1) * gap) / bars.length;
    var x = padLeft;

    for (var i = 1; i <= 3; i++) {
      final y = size.height - padBottom - plotHeight * (i / 4);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        Paint()
          ..color = style.gridColor
          ..strokeWidth = 1,
      );
    }

    for (final bar in bars) {
      final barHeight = plotHeight * bar.value;
      final top = size.height - padBottom - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = bar.color.withValues(alpha: 0.88),
      );

      final valueLabel = '${(bar.value * 100).round()}%';
      final valuePainter = TextPainter(
        text: TextSpan(
          text: valueLabel,
          style: TextStyle(
            color: bar.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(x + (barWidth - valuePainter.width) / 2, top - 18),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: TextStyle(
            color: style.labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: barWidth + 12);
      labelPainter.paint(
        canvas,
        Offset(
          x + (barWidth - labelPainter.width) / 2,
          size.height - padBottom + 10,
        ),
      );

      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarConceptGraphPainter oldDelegate) {
    return bars != oldDelegate.bars || style != oldDelegate.style;
  }
}
