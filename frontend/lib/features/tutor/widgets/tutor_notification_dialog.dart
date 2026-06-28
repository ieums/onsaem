import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/notification_center.dart';
import 'package:ieum/features/tutor/providers/tutor_notification_provider.dart';

/// 강사 알림 — 학생과 동일한 공용 알림 센터 다이얼로그 사용.
Future<void> showTutorNotificationDialog(BuildContext context, WidgetRef ref) {
  final inbox = ref.read(tutorNotificationInboxProvider);
  final items = [
    for (final n in inbox)
      NotificationViewData(
        id: n.id,
        title: n.title,
        body: n.body,
        createdAt: n.createdAt,
        isRead: n.isRead,
        kind: n.kind,
      ),
  ];
  return showNotificationCenterDialog(
    context,
    items: items,
    onMarkAllRead: () =>
        ref.read(tutorNotificationInboxProvider.notifier).markAllRead(),
    onRemoveAt: (i) =>
        ref.read(tutorNotificationInboxProvider.notifier).removeAt(i),
  );
}
