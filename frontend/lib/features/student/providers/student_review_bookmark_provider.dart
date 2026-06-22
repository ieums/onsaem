import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';

final studentReviewBookmarksProvider =
    StateNotifierProvider<StudentReviewBookmarkNotifier, Set<String>>((ref) {
  return StudentReviewBookmarkNotifier();
});

class StudentReviewBookmarkNotifier extends StateNotifier<Set<String>> {
  StudentReviewBookmarkNotifier()
      : super(
          StudentReviewDummyData.items
              .where((item) => item.isBookmarked)
              .map((item) => item.id)
              .toSet(),
        );

  bool isBookmarked(String id) => state.contains(id);

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }
}
