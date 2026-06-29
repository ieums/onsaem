import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

/// 강사 정산 달력(tutor_settlement_screen.dart)의 **순수 날짜 선택 디자인만** 본뜬 공통 피커.
/// - 월 헤더(연/월 이동·연도탭) + day 동그라미 그리드 + 연도 휠 + 월 그리드 + 스텝 헤더.
/// - 금액줄/거래상세/캐시/거래기반 연도범위 등 정산 전용 요소는 전부 제외.
/// - 선택색은 [roleColor](강사 연보라 / 학생 연두). 선택 글자색은 onPrimaryFill(밝기 대응).
/// - 날짜를 탭하면 그 날짜로 닫힘. 취소/바깥 탭이면 null.
Future<DateTime?> showRoleDatePicker({
  required BuildContext context,
  required Color roleColor,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '날짜 선택',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _RoleDatePickerSheet(
      roleColor: roleColor,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    ),
  );
}

enum _Step { dayGrid, yearPick, monthPick }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _formatKoreanYearMonth(DateTime m) => '${m.year}년 ${m.month}월';

class _RoleDatePickerSheet extends StatefulWidget {
  const _RoleDatePickerSheet({
    required this.roleColor,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  final Color roleColor;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  @override
  State<_RoleDatePickerSheet> createState() => _RoleDatePickerSheetState();
}

class _RoleDatePickerSheetState extends State<_RoleDatePickerSheet> {
  late DateTime _displayMonth;
  _Step _step = _Step.dayGrid;
  int? _pendingYear;
  late final FixedExtentScrollController _yearController;

  static const _cellHeight = 46.0;
  static const _dayBadge = 32.0;

  int get _firstYear => widget.firstDate.year;
  int get _lastYear => widget.lastDate.year;

  @override
  void initState() {
    super.initState();
    final init = _dateOnly(widget.initialDate);
    _displayMonth = DateTime(init.year, init.month);
    _yearController =
        FixedExtentScrollController(initialItem: _yearIndex(init.year));
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  int _yearIndex(int year) => year.clamp(_firstYear, _lastYear) - _firstYear;

  void _changeMonth(int delta) => setState(() =>
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta));

  void _jumpYearWheel(int year) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_yearController.hasClients) {
        _yearController.jumpToItem(_yearIndex(year));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenH = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final body = switch (_step) {
      _Step.dayGrid => _buildDayGrid(scheme),
      _Step.yearPick => _buildYearPicker(scheme, 280),
      _Step.monthPick => _buildMonthPicker(scheme, 200),
    };

    final header = switch (_step) {
      _Step.dayGrid => _buildMonthHeader(scheme),
      _Step.yearPick => _buildStepHeader(
          scheme,
          '연도 선택',
          () => setState(() => _step = _Step.dayGrid),
        ),
      _Step.monthPick => _buildStepHeader(
          scheme,
          '${_pendingYear ?? _displayMonth.year}년 월 선택',
          () {
            final y = _pendingYear ?? _displayMonth.year;
            setState(() => _step = _Step.yearPick);
            _jumpYearWheel(y);
          },
        ),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenH * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close,
                                size: 20, color: scheme.onSurfaceVariant),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    header,
                    const SizedBox(height: 8),
                    body,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 월 헤더 (강사 _buildCalendarMonthHeader 본뜸) ──────────────────────────
  Widget _buildMonthHeader(ColorScheme scheme) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon:
              Icon(Icons.chevron_left, size: 22, color: scheme.onSurface),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              final y = _displayMonth.year;
              setState(() {
                _step = _Step.yearPick;
                _pendingYear = y;
              });
              _jumpYearWheel(y);
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatKoreanYearMonth(_displayMonth),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down,
                    size: 21, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon:
              Icon(Icons.chevron_right, size: 22, color: scheme.onSurface),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  // ─── 스텝 헤더 (강사 _buildCalendarStepHeader 본뜸) ─────────────────────────
  Widget _buildStepHeader(
      ColorScheme scheme, String title, VoidCallback onBack) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: scheme.onSurface),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  // ─── day 그리드 (강사 _buildCalendarDayGrid의 날짜 배지 부분만, 금액줄 제외) ──
  Widget _buildDayGrid(ColorScheme scheme) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final cellCount = leadingEmpty + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    final today = _dateOnly(DateTime.now());
    final selected = _dateOnly(widget.initialDate);
    final firstD = _dateOnly(widget.firstDate);
    final lastD = _dateOnly(widget.lastDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        SizedBox(
          height: rowCount * _cellHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              mainAxisExtent: _cellHeight,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = index - leadingEmpty + 1;
              final date =
                  DateTime(_displayMonth.year, _displayMonth.month, day);
              final isSelected = _isSameDay(date, selected);
              final isToday = _isSameDay(date, today);
              final inRange =
                  !date.isBefore(firstD) && !date.isAfter(lastD);

              // 강사 정산 달력 셀과 동일: 선택/오늘 모두 '테두리만 역할색(속 투명) + 역할색 숫자'.
              // (강사 오늘 셀 = Border.all(roleColor, 1.5) + 숫자 roleColor)
              final highlighted = isSelected || isToday;
              final Color textColor;
              if (!inRange) {
                textColor = scheme.onSurfaceVariant.withValues(alpha: 0.3);
              } else if (highlighted) {
                textColor = widget.roleColor;
              } else {
                textColor = scheme.onSurface;
              }

              return GestureDetector(
                onTap:
                    inRange ? () => Navigator.pop(context, date) : null,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: _dayBadge,
                    height: _dayBadge,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: (inRange && highlighted)
                          ? Border.all(color: widget.roleColor, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── 연도 휠 피커 (강사 _buildCalendarYearPicker 본뜸) ──────────────────────
  Widget _buildYearPicker(ColorScheme scheme, double bodyHeight) {
    final yearCount = _lastYear - _firstYear + 1;
    final selectedYear = _pendingYear ?? _displayMonth.year;

    return SizedBox(
      height: bodyHeight,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _yearController,
                  itemExtent: 40,
                  diameterRatio: 1.4,
                  perspective: 0.003,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) =>
                      setState(() => _pendingYear = _firstYear + index),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: yearCount,
                    builder: (context, index) {
                      final year = _firstYear + index;
                      final isSelected = year == selectedYear;
                      return Center(
                        child: Text(
                          '$year년',
                          style: TextStyle(
                            fontSize: isSelected ? 18 : 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? widget.roleColor
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                onPressed: () =>
                    setState(() => _step = _Step.monthPick),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.roleColor,
                  foregroundColor:
                      AppColors.onPrimaryFill(Theme.of(context).brightness),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '$selectedYear년 월 선택',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 월 그리드 피커 (강사 _buildCalendarMonthPicker 본뜸) ───────────────────
  Widget _buildMonthPicker(ColorScheme scheme, double bodyHeight) {
    const monthLabels = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월',
    ];
    const rowCount = 3;

    return SizedBox(
      height: bodyHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight =
              (constraints.maxHeight - 4 * 2 - 4 * (rowCount - 1)) / rowCount;
          return GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: cellHeight,
            ),
            itemCount: monthLabels.length,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected =
                  month == (_pendingYear == null ? _displayMonth.month : -1);
              return GestureDetector(
                onTap: () => setState(() {
                  _displayMonth = DateTime(
                      _pendingYear ?? _displayMonth.year, month);
                  _step = _Step.dayGrid;
                  _pendingYear = null;
                }),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.roleColor
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthLabels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.onPrimaryFill(
                              Theme.of(context).brightness)
                          : scheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
