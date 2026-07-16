import 'package:ieum/features/student/models/student_notification_category.dart';

class StudentHomeNotification {
  const StudentHomeNotification({
    required this.id,
    required this.dedupeKey,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.category,
  });

  final String id;
  final String dedupeKey;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final StudentNotificationCategory category;

  int get minutesAgo => DateTime.now().difference(createdAt).inMinutes;

  String get timeLabel {
    final minutes = minutesAgo;
    if (minutes < 1) return '방금';
    if (minutes < 60) return '$minutes분 전';
    if (minutes < 1440) return '${minutes ~/ 60}시간 전';
    return '${minutes ~/ 1440}일 전';
  }

  StudentHomeNotification copyWith({
    String? id,
    String? dedupeKey,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    StudentNotificationCategory? category,
  }) {
    return StudentHomeNotification(
      id: id ?? this.id,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dedupeKey': dedupeKey,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'category': category.name,
      };

  factory StudentHomeNotification.fromJson(Map<String, dynamic> json) {
    return StudentHomeNotification(
      id: json['id'] as String,
      dedupeKey: json['dedupeKey'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      category: StudentNotificationCategory.values.byName(
        json['category'] as String,
      ),
    );
  }
}
