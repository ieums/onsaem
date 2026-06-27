import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 전체화면 이미지 뷰어(라이트박스).
/// 여러 장이면 좌우로 스와이프해 넘기고, 각 장은 InteractiveViewer로 확대/이동한다.
/// 한 장만 넘기면 단일 뷰어처럼 동작한다.

/// 네트워크 이미지 1장 — 단일 뷰어.
void showStudentProblemImageViewerUrl(
  BuildContext context, {
  required String imageUrl,
  String? title,
}) {
  showStudentProblemImageGalleryUrls(
    context,
    imageUrls: [imageUrl],
    title: title,
  );
}

/// 네트워크 이미지 여러 장 — 좌우 스와이프 갤러리. imageUrls는 이미 절대 URL.
void showStudentProblemImageGalleryUrls(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  String? title,
}) {
  if (imageUrls.isEmpty) return;
  _showGallery(
    context,
    images: [for (final u in imageUrls) NetworkImage(u)],
    initialIndex: initialIndex,
    title: title,
  );
}

/// 메모리(bytes) 이미지 1장 — 단일 뷰어.
void showStudentProblemImageViewer(
  BuildContext context, {
  required Uint8List imageBytes,
  String? title,
}) {
  showStudentProblemImageGalleryBytes(
    context,
    imagesBytes: [imageBytes],
    title: title,
  );
}

/// 메모리(bytes) 이미지 여러 장 — 좌우 스와이프 갤러리.
void showStudentProblemImageGalleryBytes(
  BuildContext context, {
  required List<Uint8List> imagesBytes,
  int initialIndex = 0,
  String? title,
}) {
  if (imagesBytes.isEmpty) return;
  _showGallery(
    context,
    images: [for (final b in imagesBytes) MemoryImage(b)],
    initialIndex: initialIndex,
    title: title,
  );
}

void _showGallery(
  BuildContext context, {
  required List<ImageProvider> images,
  required int initialIndex,
  String? title,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) => _ImageGalleryDialog(
      images: images,
      initialIndex: initialIndex.clamp(0, images.length - 1),
      title: title,
    ),
  );
}

class _ImageGalleryDialog extends StatefulWidget {
  const _ImageGalleryDialog({
    required this.images,
    required this.initialIndex,
    this.title,
  });

  final List<ImageProvider> images;
  final int initialIndex;
  final String? title;

  @override
  State<_ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<_ImageGalleryDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // 좌우 스와이프 갤러리 — 각 장은 개별 InteractiveViewer로 확대/이동.
            PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(48),
                  child: Center(
                    child: Image(
                      image: widget.images[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
            // 상단: 제목 + 닫기
            Positioned(
              top: 4,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            // 하단: 페이지 카운터 + 점 인디케이터 (여러 장일 때만)
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / $count',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < count; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StudentProblemImageThumbnail extends StatelessWidget {
  const StudentProblemImageThumbnail({
    super.key,
    required this.imageBytes,
    this.size = 56,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.heroTag,
    this.galleryBytes,
    this.galleryIndex = 0,
  });

  final Uint8List imageBytes;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;
  final Object? heroTag;

  /// 탭 시 좌우로 넘겨 볼 전체 이미지 묶음(있으면 갤러리, 없으면 이 한 장만).
  final List<Uint8List>? galleryBytes;
  final int galleryIndex;

  @override
  Widget build(BuildContext context) {
    final imageWidth = width ?? size;
    final imageHeight = height ?? size;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.memory(
        imageBytes,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final all = galleryBytes;
          if (all != null && all.length > 1) {
            showStudentProblemImageGalleryBytes(
              context,
              imagesBytes: all,
              initialIndex: galleryIndex,
            );
          } else {
            showStudentProblemImageViewer(context, imageBytes: imageBytes);
          }
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: heroTag == null
            ? image
            : Hero(
                tag: heroTag!,
                child: image,
              ),
      ),
    );
  }
}
