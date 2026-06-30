import 'package:flutter/material.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';

/// 알림 종류 — 카테고리별 색/아이콘으로 한눈에 구분(강사·학생 공용).
enum NotificationKind {
  matching, // 신청·매칭
  lesson, // 수업/연장
  settlement, // 정산
  report, // 신고
  aiTutor, // AI 튜터
  general,
}

/// 카테고리별 '아이콘'은 의미 구분을 위해 유지하되, 색은 역할 강조색(accent)으로 통일한다.
/// (학생 알림 = 학생색, 강사 알림 = 강사색)
IconData _iconOf(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.matching:
      return Icons.person_add_alt_1;
    case NotificationKind.lesson:
      return Icons.videocam_rounded;
    case NotificationKind.settlement:
      return Icons.payments_rounded;
    case NotificationKind.report:
      return Icons.gavel_rounded;
    case NotificationKind.aiTutor:
      return Icons.smart_toy_rounded;
    case NotificationKind.general:
      return Icons.notifications_rounded;
  }
}

/// 다이얼로그에 표시할 알림 1건(학생/강사 모델을 이 형태로 변환해 전달).
class NotificationViewData {
  const NotificationViewData({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.kind,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationKind kind;

  String get timeLabel {
    final m = DateTime.now().difference(createdAt).inMinutes;
    if (m < 1) return '방금';
    if (m < 60) return '$m분 전';
    if (m < 1440) return '${m ~/ 60}시간 전';
    return '${m ~/ 1440}일 전';
  }
}

/// 공용 알림 센터 다이얼로그. 학생·강사가 같은 UI를 쓰되 [accent]만 각 역할색으로 다르게 넘긴다.
/// onMarkAllRead: 열릴 때 자동 호출. onRemoveAt: 스와이프 삭제.
Future<void> showNotificationCenterDialog(
  BuildContext context, {
  required List<NotificationViewData> items,
  required VoidCallback onMarkAllRead,
  required void Function(int index) onRemoveAt,
  required Color accent,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) => Theme(
      data: theme,
      child: _NotificationCenterDialog(
        items: items,
        onMarkAllRead: onMarkAllRead,
        onRemoveAt: onRemoveAt,
        accent: accent,
      ),
    ),
  );
}

class _NotificationCenterDialog extends StatefulWidget {
  const _NotificationCenterDialog({
    required this.items,
    required this.onMarkAllRead,
    required this.onRemoveAt,
    required this.accent,
  });

  final List<NotificationViewData> items;
  final VoidCallback onMarkAllRead;
  final void Function(int index) onRemoveAt;
  final Color accent;

  @override
  State<_NotificationCenterDialog> createState() =>
      _NotificationCenterDialogState();
}

class _NotificationCenterDialogState extends State<_NotificationCenterDialog> {
  late List<NotificationViewData> _items;
  String? _swipedOpenId;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onMarkAllRead());
  }

  void _removeAt(int index) {
    setState(() {
      _swipedOpenId = null;
      _items.removeAt(index);
    });
    widget.onRemoveAt(index);
  }

  /// '모두 읽음'을 누르면 즉시 화면에도 반영(재진입 없이). 로컬 스냅샷을 읽음 상태로 갱신.
  void _markAllReadLocal() {
    setState(() {
      _items = [
        for (final i in _items)
          NotificationViewData(
            id: i.id,
            title: i.title,
            body: i.body,
            createdAt: i.createdAt,
            isRead: true,
            kind: i.kind,
          ),
      ];
    });
  }

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final today = _items.where((i) => _isToday(i.createdAt)).toList();
    final earlier = _items.where((i) => !_isToday(i.createdAt)).toList();

    return Dialog(
      backgroundColor: shell.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '알림',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                const Spacer(),
                if (_items.any((i) => !i.isRead))
                  TextButton(
                    onPressed: () {
                      widget.onMarkAllRead();
                      _markAllReadLocal();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('모두 읽음',
                        style:
                            TextStyle(fontSize: 12.5, color: shell.hintColor)),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: shell.hintColor),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 8, 28),
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
                    maxHeight: MediaQuery.sizeOf(context).height * 0.56,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8, right: 4),
                    children: [
                      if (today.isNotEmpty) ...[
                        _groupHeader(shell, '오늘'),
                        ..._rows(shell, today),
                      ],
                      if (earlier.isNotEmpty) ...[
                        _groupHeader(shell, '이전'),
                        ..._rows(shell, earlier),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(ShellTheme shell, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 0, 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: shell.hintColor,
          ),
        ),
      );

  List<Widget> _rows(ShellTheme shell, List<NotificationViewData> group) {
    return [
      for (final item in group)
        _SwipeDeleteRow(
          key: ValueKey(item.id),
          item: item,
          shell: shell,
          accent: widget.accent,
          isOpen: _swipedOpenId == item.id,
          onOpen: () => setState(() => _swipedOpenId = item.id),
          onClose: () {
            if (_swipedOpenId == item.id) setState(() => _swipedOpenId = null);
          },
          onDelete: () => _removeAt(_items.indexOf(item)),
        ),
    ];
  }
}

class _SwipeDeleteRow extends StatefulWidget {
  const _SwipeDeleteRow({
    super.key,
    required this.item,
    required this.shell,
    required this.accent,
    required this.isOpen,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final NotificationViewData item;
  final ShellTheme shell;
  final Color accent;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  static const _deleteWidth = 76.0;

  @override
  State<_SwipeDeleteRow> createState() => _SwipeDeleteRowState();
}

class _SwipeDeleteRowState extends State<_SwipeDeleteRow> {
  double _dx = 0;

  @override
  void didUpdateWidget(covariant _SwipeDeleteRow old) {
    super.didUpdateWidget(old);
    if (!widget.isOpen && old.isOpen) _dx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: const Color(0xFFD64545),
                child: InkWell(
                  onTap: widget.onDelete,
                  child: const SizedBox(
                    width: _SwipeDeleteRow._deleteWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 21),
                        SizedBox(height: 3),
                        Text('삭제',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (d) {
              final next =
                  (_dx + d.delta.dx).clamp(-_SwipeDeleteRow._deleteWidth, 0.0);
              if (next != _dx) setState(() => _dx = next);
            },
            onHorizontalDragEnd: (_) {
              if (_dx <= -_SwipeDeleteRow._deleteWidth / 2) {
                setState(() => _dx = -_SwipeDeleteRow._deleteWidth);
                widget.onOpen();
              } else {
                setState(() => _dx = 0);
                widget.onClose();
              }
            },
            onTap: widget.isOpen
                ? () {
                    setState(() => _dx = 0);
                    widget.onClose();
                  }
                : null,
            child: Transform.translate(
              offset: Offset(_dx, 0),
              child: _Row(
                  item: widget.item, shell: widget.shell, accent: widget.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.shell, required this.accent});
  final NotificationViewData item;
  final ShellTheme shell;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = _iconOf(item.kind);
    // 색은 역할 강조색(accent)으로 통일 — 아이콘 원 배경은 옅은 틴트, 강조는 진한 accent.
    final iconBg = accent.withValues(alpha: 0.14);
    return Container(
      // 안 읽은 알림: 역할색 옅은 틴트(불투명)로 강조 + 왼쪽 색 바.
      // 반투명이면 뒤 삭제 버튼이 비쳐 보여 → cardBackground 위에 합성해 불투명 처리.
      decoration: BoxDecoration(
        color: item.isRead
            ? shell.cardBackground
            : Color.alphaBlend(
                accent.withValues(alpha: 0.12), shell.cardBackground),
        border: item.isRead
            ? null
            : Border(left: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 14.5,
                          fontWeight:
                              item.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: shell.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.timeLabel,
                        style:
                            TextStyle(fontSize: 11.5, color: shell.hintColor)),
                  ],
                ),
                const SizedBox(height: 4),
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
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 6),
              decoration:
                  BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
