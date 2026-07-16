import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/widgets/shell_filter_chip.dart';

/// 정렬·필터 등 팝업 메뉴 라벨 너비 측정
double measureShellMenuLabelWidth(
  List<String> labels, {
  double fontSize = 14,
  double horizontalPadding = 40,
}) {
  final painter = TextPainter(textDirection: TextDirection.ltr);
  var maxText = 0.0;
  for (final label in labels) {
    for (final weight in [FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
      painter.text = TextSpan(
        text: label,
        style: TextStyle(fontSize: fontSize, fontWeight: weight),
      );
      painter.layout();
      if (painter.width > maxText) maxText = painter.width;
    }
  }
  return maxText + horizontalPadding;
}

/// 앵커(아이콘) 아래 셸 테마 팝업 메뉴
Future<T?> showShellAnchorPopupMenu<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required List<PopupMenuEntry<T>> items,
  required double menuWidth,
}) {
  final box = anchorContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Future.value();

  final offset = box.localToGlobal(Offset.zero);
  final screenSize = MediaQuery.sizeOf(context);
  final left = (offset.dx + box.size.width - menuWidth)
      .clamp(8.0, screenSize.width - menuWidth - 8);
  final scheme = Theme.of(anchorContext).colorScheme;

  return showMenu<T>(
    context: anchorContext,
    color: scheme.surface,
    elevation: 6,
    menuPadding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: scheme.outline),
    ),
    constraints: BoxConstraints.tightFor(width: menuWidth),
    position: RelativeRect.fromLTRB(
      left,
      offset.dy + box.size.height + 8,
      screenSize.width - left - menuWidth,
      screenSize.height - offset.dy - box.size.height - 8,
    ),
    items: items,
  );
}

PopupMenuItem<T> buildShellPopupMenuItem<T>({
  required BuildContext context,
  required T value,
  required String label,
  required double menuWidth,
  required bool isSelected,
  bool isFirst = false,
  bool isLast = false,
  double cornerRadius = 14,
  double height = 46,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
}) {
  final scheme = Theme.of(context).colorScheme;
  BorderRadius? rowRadius;
  if (isSelected) {
    if (isFirst && isLast) {
      rowRadius = BorderRadius.circular(cornerRadius);
    } else if (isFirst) {
      rowRadius = BorderRadius.vertical(top: Radius.circular(cornerRadius));
    } else if (isLast) {
      rowRadius = BorderRadius.vertical(bottom: Radius.circular(cornerRadius));
    }
  }

  return PopupMenuItem<T>(
    value: value,
    height: height,
    padding: EdgeInsets.zero,
    child: SizedBox(
      width: menuWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: shellPopupMenuRowColor(context, selected: isSelected),
          borderRadius: rowRadius,
        ),
        child: Padding(
          padding: padding,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.onPrimaryFill(Theme.of(context).brightness)
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}
