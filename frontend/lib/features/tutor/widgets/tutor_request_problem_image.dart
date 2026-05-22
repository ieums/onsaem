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
        child: _ProblemImagePlaceholder(size: size),
      ),
    );
  }
}

/// 문제 이미지 확대 뷰어 (API URL 연동 전 플레이스홀더).
void showTutorRequestProblemImageViewer(
  BuildContext context,
  TutorRequestListItem item,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (dialogContext) {
      final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.78;
      final title = item.chapter.isEmpty
          ? item.detailSubject
          : '${item.detailSubject} · ${item.chapter}';

      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D26),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, size: 22),
                    color: const Color(0xFF1A1D26),
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
            SizedBox(
              height: maxHeight,
              width: double.infinity,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _ProblemImagePlaceholder(
                      size: maxHeight * 0.85,
                      large: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ProblemImagePlaceholder extends StatelessWidget {
  const _ProblemImagePlaceholder({
    required this.size,
    this.large = false,
  });

  final double size;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: large ? 64 : 40,
            color: const Color(0xFFB8BEC9),
          ),
          if (large) ...[
            const SizedBox(height: 12),
            const Text(
              '문제 이미지',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9AA3B2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
