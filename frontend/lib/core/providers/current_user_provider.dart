import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSession {
  final int id;
  final bool isTutor;
  const UserSession({required this.id, required this.isTutor});
}

final currentUserProvider = StateProvider<UserSession?>((ref) => null);
