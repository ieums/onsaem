import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';

/// 리스트 썸네일 — 탭 시 [showTutorRequestProblemImageViewer].
class TutorRequestProblemThumbnail extends StatelessWidget {
  const TutorRequestProblemThumbnail({
    super.key,
    required this.item,
    this.size = 88,
  });

  final TutorRequestListItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showTutorRequestProblemImageViewer(context, item),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _ProblemImagePlaceholder(
            width: size,
            height: size,
          ),
        ),
      ),
    );
  }
}

/// 문제 이미지 확대 뷰어.
void showTutorRequestProblemImageViewer(
  BuildContext context,
  TutorRequestListItem item,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final media = MediaQuery.of(dialogContext);
      final screenSize = media.size;
      final title = item.chapter.isEmpty
          ? item.detailSubject
          : '${item.detailSubject} · ${item.chapter}';

      const horizontalInset = 20.0;
      const verticalInset = 24.0;
      final maxDialogWidth = screenSize.width - horizontalInset * 2;
      final maxDialogHeight = screenSize.height -
          media.padding.top -
          media.padding.bottom -
          verticalInset * 2;

      return Dialog(
        backgroundColor: scheme.surface,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: verticalInset,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, size: 22),
                      color: scheme.onSurfaceVariant,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final displaySize = _resolveViewerImageSize(
                      maxWidth: constraints.maxWidth - 24,
                      maxHeight: constraints.maxHeight - 12,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Center(
                        child: SizedBox(
                          width: displaySize.width,
                          height: displaySize.height,
                          child: InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4,
                            clipBehavior: Clip.hardEdge,
                            boundaryMargin: const EdgeInsets.all(48),
                            child: _ProblemImagePlaceholder(
                              width: displaySize.width,
                              height: displaySize.height,
                              large: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 뷰어 영역 — 화면에 맞는 3:4 비율 (API 이미지 연동 시 확장).
Size _resolveViewerImageSize({
  required double maxWidth,
  required double maxHeight,
}) {
  final maxW = math.max(maxWidth, 120.0);
  final maxH = math.max(maxHeight, 120.0);

  var w = maxW;
  var h = w * 4 / 3;
  if (h > maxH) {
    h = maxH;
    w = h * 3 / 4;
  }
  return Size(w, h);
}

class _ProblemImagePlaceholder extends StatelessWidget {
  const _ProblemImagePlaceholder({
    required this.width,
    required this.height,
    this.large = false,
  });

  final double width;
  final double height;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shortSide = width < height ? width : height;
    final iconSize = large ? shortSide * 0.22 : 40.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: iconSize.clamp(28.0, 64.0),
            color: scheme.onSurfaceVariant,
          ),
          if (large && height >= 100) ...[
            const SizedBox(height: 8),
            Text(
              '문제 이미지',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
