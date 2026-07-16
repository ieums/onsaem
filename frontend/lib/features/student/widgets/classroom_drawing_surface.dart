import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/constants/classroom_tool_assets.dart';

enum ClassroomDrawTool { pen, eraser, highlighter }

class ClassroomStroke {
  ClassroomStroke({
    required this.tool,
    required this.color,
    required this.points,
    required this.strokeWidth,
  });

  final ClassroomDrawTool tool;
  final Color color;
  final List<Offset> points;
  final double strokeWidth;
}

class ClassroomDrawingSurface extends StatefulWidget {
  const ClassroomDrawingSurface({
    super.key,
    this.frameBorderColor,
    this.background,
    this.emptyTitle = '화이트보드',
    this.emptySubtitle = '강사님과 함께 풀이를 작성해 보세요',
    this.emptyIcon = Icons.draw_rounded,
  });

  final Color? frameBorderColor;
  final Widget? background;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  @override
  State<ClassroomDrawingSurface> createState() =>
      _ClassroomDrawingSurfaceState();
}

class _ClassroomDrawingSurfaceState extends State<ClassroomDrawingSurface> {
  static const _penColors = [
    Color(0xFF1A1D26),
    Color(0xFFE53935),
    AppColors.vividBlue,
  ];
  static const _highlighterColors = [
    Color(0xFFFFEB3B),
    Color(0xFF8BC34A),
    Color(0xFF4FC3F7),
  ];

  static const _penSizeRange = (min: 2.0, max: 8.0);
  static const _highlighterSizeRange = (min: 10.0, max: 28.0);
  static const _eraserSizeRange = (min: 14.0, max: 42.0);

  final _strokes = <ClassroomStroke>[];
  ClassroomDrawTool _tool = ClassroomDrawTool.pen;
  int _penColorIndex = 0;
  int _highlighterColorIndex = 0;
  double _penSize = 3;
  double _highlighterSize = 16;
  double _eraserSize = 24;
  ClassroomStroke? _activeStroke;
  bool _isToolPaletteExpanded = true;

  Color get _selectedColor => switch (_tool) {
        ClassroomDrawTool.pen => _penColors[_penColorIndex],
        ClassroomDrawTool.highlighter =>
          _highlighterColors[_highlighterColorIndex],
        ClassroomDrawTool.eraser => Colors.transparent,
      };

  double get _strokeWidth => switch (_tool) {
        ClassroomDrawTool.pen => _penSize,
        ClassroomDrawTool.highlighter => _highlighterSize,
        ClassroomDrawTool.eraser => _eraserSize,
      };

  ({double min, double max}) get _sizeRange => switch (_tool) {
        ClassroomDrawTool.pen => _penSizeRange,
        ClassroomDrawTool.highlighter => _highlighterSizeRange,
        ClassroomDrawTool.eraser => _eraserSizeRange,
      };

  double get _currentToolSize => switch (_tool) {
        ClassroomDrawTool.pen => _penSize,
        ClassroomDrawTool.highlighter => _highlighterSize,
        ClassroomDrawTool.eraser => _eraserSize,
      };

  List<Color> get _paletteColors => switch (_tool) {
        ClassroomDrawTool.pen => _penColors,
        ClassroomDrawTool.highlighter => _highlighterColors,
        ClassroomDrawTool.eraser => const [],
      };

  int get _paletteIndex => switch (_tool) {
        ClassroomDrawTool.pen => _penColorIndex,
        ClassroomDrawTool.highlighter => _highlighterColorIndex,
        ClassroomDrawTool.eraser => 0,
      };

  void _setPaletteIndex(int index) {
    setState(() {
      switch (_tool) {
        case ClassroomDrawTool.pen:
          _penColorIndex = index;
        case ClassroomDrawTool.highlighter:
          _highlighterColorIndex = index;
        case ClassroomDrawTool.eraser:
          break;
      }
    });
  }

  void _setToolSize(double value) {
    setState(() {
      switch (_tool) {
        case ClassroomDrawTool.pen:
          _penSize = value;
        case ClassroomDrawTool.highlighter:
          _highlighterSize = value;
        case ClassroomDrawTool.eraser:
          _eraserSize = value;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
  }

  void _undoLastStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _activeStroke = null;
    });
  }

  void _startStroke(Offset point) {
    setState(() {
      _activeStroke = ClassroomStroke(
        tool: _tool,
        color: _selectedColor,
        points: [point],
        strokeWidth: _strokeWidth,
      );
    });
  }

  void _extendStroke(Offset point) {
    final stroke = _activeStroke;
    if (stroke == null) return;
    setState(() {
      stroke.points.add(point);
    });
  }

  void _endStroke() {
    final stroke = _activeStroke;
    if (stroke == null || stroke.points.length < 2) {
      setState(() => _activeStroke = null);
      return;
    }
    setState(() {
      _strokes.add(stroke);
      _activeStroke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    const canvasColor = Colors.white;
    final frameBorder = widget.frameBorderColor ?? shell.cardBorder;
    final palette = _paletteColors;
    final sizeRange = _sizeRange;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
        final hasDrawing = _strokes.isNotEmpty || _activeStroke != null;
        final showEmptyHint = !hasDrawing && widget.background == null;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: canvasColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: frameBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.background != null)
                        widget.background!
                      else
                        ColoredBox(color: canvasColor),
                      if (showEmptyHint)
                        Positioned.fill(
                          child: _EmptyHint(
                            shell: shell,
                            title: widget.emptyTitle,
                            subtitle: widget.emptySubtitle,
                            icon: widget.emptyIcon,
                          ),
                        ),
                      CustomPaint(
                        painter: _DrawingPainter(
                          strokes: [
                            ..._strokes,
                            ?_activeStroke,
                          ],
                        ),
                        size: boardSize,
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: (details) =>
                              _startStroke(details.localPosition),
                          onPanUpdate: (details) =>
                              _extendStroke(details.localPosition),
                          onPanEnd: (_) => _endStroke(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _ToolPalette(
                expanded: _isToolPaletteExpanded,
                onToggleExpanded: () => setState(
                  () => _isToolPaletteExpanded = !_isToolPaletteExpanded,
                ),
                tool: _tool,
                paletteColors: palette,
                paletteIndex: _paletteIndex,
                toolSize: _currentToolSize,
                sizeMin: sizeRange.min,
                sizeMax: sizeRange.max,
                onToolChanged: (tool) => setState(() => _tool = tool),
                onPaletteIndexChanged: _setPaletteIndex,
                onToolSizeChanged: _setToolSize,
                canUndo: _strokes.isNotEmpty,
                onUndo: _undoLastStroke,
                onClearAll: _clearAll,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.shell,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ShellTheme shell;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 44,
              color: AppColors.shellHintLight,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.shellOnSurfaceLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.shellSubtitleLight,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ToolPalette extends StatelessWidget {
  const _ToolPalette({
    required this.expanded,
    required this.onToggleExpanded,
    required this.tool,
    required this.paletteColors,
    required this.paletteIndex,
    required this.toolSize,
    required this.sizeMin,
    required this.sizeMax,
    required this.onToolChanged,
    required this.onPaletteIndexChanged,
    required this.onToolSizeChanged,
    required this.canUndo,
    required this.onUndo,
    required this.onClearAll,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ClassroomDrawTool tool;
  final List<Color> paletteColors;
  final int paletteIndex;
  final double toolSize;
  final double sizeMin;
  final double sizeMax;
  final ValueChanged<ClassroomDrawTool> onToolChanged;
  final ValueChanged<int> onPaletteIndexChanged;
  final ValueChanged<double> onToolSizeChanged;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    const background = Colors.white;
    const dividerColor = AppColors.shellCardBorderLight;
    const idleIconColor = AppColors.shellSubtitleLight;
    const shadowColor = Color(0x14000000);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: 52,
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: expanded ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
        boxShadow: const [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolIconButton(
            selected: false,
            onTap: onToggleExpanded,
            child: const Icon(
              Icons.menu_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            sizeCurve: Curves.easeInOut,
            firstChild: const SizedBox(width: 36, height: 0),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 28, height: 1, color: dividerColor),
                const SizedBox(height: 8),
                _ToolIconButton(
                  selected: false,
                  enabled: canUndo,
                  onTap: onUndo,
                  child: Icon(
                    Icons.undo_rounded,
                    size: 20,
                    color: canUndo
                        ? AppColors.studentInk
                        : idleIconColor.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 8),
                _ToolIconButton(
                  selected: false,
                  onTap: onClearAll,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.logoutRed.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 28, height: 1, color: dividerColor),
                const SizedBox(height: 8),
                _ToolIconButton(
                  selected: tool == ClassroomDrawTool.pen,
                  onTap: () => onToolChanged(ClassroomDrawTool.pen),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: tool == ClassroomDrawTool.pen
                        ? Colors.white
                        : idleIconColor,
                  ),
                ),
                const SizedBox(height: 8),
                _ToolIconButton(
                  selected: tool == ClassroomDrawTool.eraser,
                  onTap: () => onToolChanged(ClassroomDrawTool.eraser),
                  child: _ClassroomToolAssetIcon(
                    assetPath: ClassroomToolAssets.eraser,
                    color: tool == ClassroomDrawTool.eraser
                        ? Colors.white
                        : idleIconColor,
                  ),
                ),
                const SizedBox(height: 8),
                _ToolIconButton(
                  selected: tool == ClassroomDrawTool.highlighter,
                  onTap: () => onToolChanged(ClassroomDrawTool.highlighter),
                  child: _ClassroomToolAssetIcon(
                    assetPath: ClassroomToolAssets.highlighter,
                    color: tool == ClassroomDrawTool.highlighter
                        ? Colors.white
                        : idleIconColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 28, height: 1, color: dividerColor),
                const SizedBox(height: 8),
                SizedBox(
                  height: 92,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: AppColors.studentInk,
                        inactiveTrackColor: dividerColor,
                        thumbColor: AppColors.studentInk,
                      ),
                      child: Slider(
                        value: toolSize,
                        min: sizeMin,
                        max: sizeMax,
                        onChanged: onToolSizeChanged,
                      ),
                    ),
                  ),
                ),
                if (paletteColors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(width: 28, height: 1, color: dividerColor),
                  const SizedBox(height: 8),
                  for (var i = 0; i < paletteColors.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _ColorSwatch(
                      color: paletteColors[i],
                      selected: i == paletteIndex,
                      onTap: () => onPaletteIndexChanged(i),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomToolAssetIcon extends StatelessWidget {
  const _ClassroomToolAssetIcon({
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color color;
  static const _size = 18.0;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: _size,
      height: _size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  const _ToolIconButton({
    required this.selected,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.vividBlue : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.studentInk : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.studentPoint.withValues(alpha: 0.35),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({required this.strokes});

  final List<ClassroomStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth;

      if (stroke.tool == ClassroomDrawTool.eraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      } else if (stroke.tool == ClassroomDrawTool.highlighter) {
        paint.color = stroke.color.withValues(alpha: 0.38);
      } else {
        paint.color = stroke.color;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final previous = stroke.points[i - 1];
        final current = stroke.points[i];
        final mid = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
