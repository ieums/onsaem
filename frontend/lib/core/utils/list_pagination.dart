/// 리스트 페이지네이션 유틸
abstract final class ListPagination {
  static int pageCount(int itemCount, int pageSize) {
    if (itemCount == 0 || pageSize <= 0) return 0;
    return (itemCount / pageSize).ceil();
  }

  static int clampPageIndex(int pageIndex, int pageCount) {
    if (pageCount == 0) return 0;
    return pageIndex.clamp(0, pageCount - 1);
  }

  static List<T> slice<T>(
    List<T> items, {
    required int pageIndex,
    required int pageSize,
  }) {
    if (items.isEmpty || pageSize <= 0) return [];

    final count = pageCount(items.length, pageSize);
    final safeIndex = clampPageIndex(pageIndex, count);
    final start = safeIndex * pageSize;
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }
}
