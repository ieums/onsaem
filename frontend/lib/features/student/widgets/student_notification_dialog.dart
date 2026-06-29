import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/notifications/notification_center.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/student/models/student_notification_category.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';

NotificationKind _kindOf(StudentNotificationCategory c) => switch (c) {
      StudentNotificationCategory.matching => NotificationKind.matching,
      StudentNotificationCategory.aiTutor => NotificationKind.aiTutor,
      StudentNotificationCategory.extendTime => NotificationKind.lesson,
    };

/// 학생 알림 — 공용 알림 센터 다이얼로그 사용.
Future<void> showStudentNotificationDialog(
    BuildContext context, WidgetRef ref) {
  final inbox = ref.read(studentNotificationInboxProvider);
  final items = [
    for (final n in inbox)
      NotificationViewData(
        id: n.id,
        title: n.title,
        body: n.body,
        createdAt: n.createdAt,
        isRead: n.isRead,
        kind: _kindOf(n.category),
      ),
  ];
  return showNotificationCenterDialog(
    context,
    items: items,
    onMarkAllRead: () =>
        ref.read(studentNotificationInboxProvider.notifier).markAllRead(),
    onRemoveAt: (i) =>
        ref.read(studentNotificationInboxProvider.notifier).removeAt(i),
    accent: AppColors.studentPoint, // 학생 강조색(연두)
  );
}
