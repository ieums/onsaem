import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_home_notification.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';

Future<void> showStudentNotificationDialog(BuildContext context) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) {
      return Theme(
        data: theme,
        child: const _StudentNotificationDialog(),
      );
    },
  );
}

class _StudentNotificationDialog extends ConsumerStatefulWidget {
  const _StudentNotificationDialog();

  @override
  ConsumerState<_StudentNotificationDialog> createState() =>
      _StudentNotificationDialogState();
}

class _StudentNotificationDialogState
    extends ConsumerState<_StudentNotificationDialog> {
  String? _swipedOpenId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotificationInboxProvider.notifier).markAllRead();
    });
  }

  void _removeAt(int index) {
    setState(() => _swipedOpenId = null);
    ref.read(studentNotificationInboxProvider.notifier).removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final items = ref.watch(studentNotificationInboxProvider);

    return Dialog(
      backgroundColor: shell.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '알림',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: shell.titleColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: shell.hintColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 8, 24),
                child: Text(
                  '새 알림이 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: shell.hintColor),
                ),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: shell.cardBorder.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _SwipeDeleteNotificationRow(
                        key: ValueKey(item.id),
                        item: item,
                        shell: shell,
                        isOpen: _swipedOpenId == item.id,
                        onOpen: () => setState(() => _swipedOpenId = item.id),
                        onClose: () {
                          if (_swipedOpenId == item.id) {
                            setState(() => _swipedOpenId = null);
                          }
                        },
                        onDelete: () => _removeAt(index),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteNotificationRow extends StatefulWidget {
  const _SwipeDeleteNotificationRow({
    super.key,
    required this.item,
    required this.shell,
    required this.isOpen,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final StudentHomeNotification item;
  final ShellTheme shell;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  static const _deleteActionWidth = 80.0;

  @override
  State<_SwipeDeleteNotificationRow> createState() =>
      _SwipeDeleteNotificationRowState();
}

class _SwipeDeleteNotificationRowState
    extends State<_SwipeDeleteNotificationRow> {
  double _dragOffset = 0;

  @override
  void didUpdateWidget(covariant _SwipeDeleteNotificationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen && oldWidget.isOpen) {
      _dragOffset = 0;
    }
  }

  void _snapOpen() {
    setState(() {
      _dragOffset = -_SwipeDeleteNotificationRow._deleteActionWidth;
    });
    widget.onOpen();
  }

  void _snapClosed() {
    setState(() => _dragOffset = 0);
    widget.onClose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final nextOffset = (_dragOffset + details.delta.dx).clamp(
      -_SwipeDeleteNotificationRow._deleteActionWidth,
      0.0,
    );
    if (nextOffset != _dragOffset) {
      setState(() => _dragOffset = nextOffset);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen =
        _dragOffset <= -_SwipeDeleteNotificationRow._deleteActionWidth / 2;
    if (shouldOpen) {
      _snapOpen();
    } else {
      _snapClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: AppColors.logoutRed,
                child: InkWell(
                  onTap: widget.onDelete,
                  child: SizedBox(
                    width: _SwipeDeleteNotificationRow._deleteActionWidth,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '삭제',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onTap: widget.isOpen ? _snapClosed : null,
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: ColoredBox(
                color: widget.shell.cardBackground,
                child: _NotificationRow(item: widget.item, shell: widget.shell),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.shell,
  });

  final StudentHomeNotification item;
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: item.isRead ? Colors.transparent : AppColors.logoutRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: shell.titleColor,
                        ),
                      ),
                    ),
                    Text(
                      item.timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: shell.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: shell.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
