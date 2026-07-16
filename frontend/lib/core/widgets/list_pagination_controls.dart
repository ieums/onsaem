import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';

class ListPaginationControls extends StatelessWidget {
  const ListPaginationControls({
    super.key,
    required this.pageIndex,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    this.padding = const EdgeInsets.only(top: 4),
  });

  final int pageIndex;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();

    final shell = ShellTheme.of(context);
    final canGoPrev = pageIndex > 0;
    final canGoNext = pageIndex < pageCount - 1;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoPrev ? onPrevious : null,
            icon: Icon(
              Icons.chevron_left,
              size: 22,
              color: canGoPrev ? shell.titleColor : shell.hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${pageIndex + 1} / $pageCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: shell.titleColor,
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoNext ? shell.titleColor : shell.hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
