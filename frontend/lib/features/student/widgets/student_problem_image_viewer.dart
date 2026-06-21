import 'dart:typed_data';

import 'package:flutter/material.dart';

class StudentProblemImageThumbnail extends StatelessWidget {
  const StudentProblemImageThumbnail({
    super.key,
    required this.imageBytes,
    this.size = 56,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.heroTag,
  });

  final Uint8List imageBytes;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;
  final Object? heroTag;

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
        onTap: () => showStudentProblemImageViewer(
          context,
          imageBytes: imageBytes,
        ),
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

void showStudentProblemImageViewer(
  BuildContext context, {
  required Uint8List imageBytes,
  String? title,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(48),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title,
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
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
