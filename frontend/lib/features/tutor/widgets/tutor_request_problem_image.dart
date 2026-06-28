import 'package:flutter/material.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';

/// 리스트 썸네일 — 탭 시 그 문제의 이미지들을 좌우 스와이프로(확대 없이) 본다.
class TutorRequestProblemThumbnail extends StatelessWidget {
  const TutorRequestProblemThumbnail({
    super.key,
    this.imageUrls = const [],
    this.title,
    this.size = 88,
  });

  final List<String> imageUrls;
  final String? title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final first = imageUrls.isNotEmpty ? imageUrls.first : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: imageUrls.isEmpty
            ? null
            : () => showStudentProblemImageGalleryUrls(
                  context,
                  imageUrls: [
                    for (final u in imageUrls) ApiConstants.resolveImageUrl(u),
                  ],
                  title: title,
                  zoomable: false, // 확대 불가, 좌우로만 넘김
                ),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildThumbnailContent(context, first),
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(BuildContext context, String? first) {
    if (first != null) {
      return Image.network(
        ApiConstants.resolveImageUrl(first),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ProblemImagePlaceholder(
          width: size,
          height: size,
        ),
      );
    }
    return _ProblemImagePlaceholder(width: size, height: size);
  }
}
class _ProblemImagePlaceholder extends StatelessWidget {
  const _ProblemImagePlaceholder({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
