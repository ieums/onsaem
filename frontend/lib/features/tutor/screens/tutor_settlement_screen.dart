import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/tutor/data/tutor_settlement_dummy_data.dart';

enum _ChartPeriod { weekly, monthly, yearly }

enum _HistoryFilter { all, deposit, withdrawal }

enum _CalendarPickerStep { dayGrid, yearPick, monthPick }

class _SettlementHistoryItem {
  const _SettlementHistoryItem({
    required this.date,
    required this.title,
    required this.amount,
  });

  final DateTime date;
  final String title;
  final int amount;

  bool get isIncome => amount > 0;
}

class _CalendarTransaction {
  const _CalendarTransaction({
    required this.date,
    required this.label,
    required this.amount,
    this.filledFromPriorYear = false,
  });

  factory _CalendarTransaction.fromDummy(
    TutorSettlementCalendarTransaction transaction,
  ) {
    return _CalendarTransaction(
      date: transaction.date,
      label: transaction.label,
      amount: transaction.amount,
      filledFromPriorYear: transaction.filledFromPriorYear,
    );
  }

  final DateTime date;
  final String label;
  final int amount;
  final bool filledFromPriorYear;

  bool get isDeposit => amount > 0;

  String get fullDateTimeLabel => _formatFullDateTime(date);
}

String _formatFullDateTime(DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '$year.$month.$day $hour:$minute:$second';
}

class TutorSettlementScreen extends StatefulWidget {
  const TutorSettlementScreen({super.key});

  @override
  State<TutorSettlementScreen> createState() => _TutorSettlementScreenState();
}

class _TutorSettlementScreenState extends State<TutorSettlementScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _labelColor = Color(0xFF1A1D26);
  static const _hintColor = Color(0xFF9AA3B2);
  static const _borderColor = Color(0xFFE0E0E0);
  static const _incomeColor = Color(0xFF2E9E6A);
  static const _expenseColor = Color(0xFFE53935);

  static const _weekLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _yearLabels = [
    '1월',
    '2월',
    '3월',
    '4월',
    '5월',
    '6월',
    '7월',
    '8월',
    '9월',
    '10월',
    '11월',
    '12월',
  ];

  /// 더미 기준일 (개발 중 고정, 출시 시 DateTime.now()로 교체)
  static DateTime get _chartReferenceDate =>
      TutorSettlementDummyData.referenceDate;

  static const _historyMaxItems = 10;
  static const _historyPageSize = 5;

  List<_SettlementHistoryItem> get _filteredSettlementHistory {
    final List<_SettlementHistoryItem> filtered;
    switch (_historyFilter) {
      case _HistoryFilter.all:
        filtered = _settlementHistory;
        break;
      case _HistoryFilter.deposit:
        filtered =
            _settlementHistory.where((item) => item.isIncome).toList();
        break;
      case _HistoryFilter.withdrawal:
        filtered =
            _settlementHistory.where((item) => !item.isIncome).toList();
        break;
    }

    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(_historyMaxItems).toList();
  }

  int get _historyPageCount {
    final count = _filteredSettlementHistory.length;
    if (count == 0) return 0;
    return (count / _historyPageSize).ceil();
  }

  List<_SettlementHistoryItem> get _pagedSettlementHistory {
    final items = _filteredSettlementHistory;
    if (items.isEmpty) return [];

    final safePageIndex = _historyPageIndex.clamp(0, _historyPageCount - 1);
    final start = safePageIndex * _historyPageSize;
    final end = (start + _historyPageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  List<_SettlementHistoryItem> get _settlementHistory {
    final sorted = [..._realizedCalendarTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return [
      for (final tx in sorted)
        _SettlementHistoryItem(
          date: tx.date,
          title: tx.isDeposit ? '수업 완료' : '출금',
          amount: tx.amount,
        ),
    ];
  }

  List<_CalendarTransaction>? _allCalendarTransactionsCache;
  Map<String, List<_CalendarTransaction>>? _transactionsByDayCache;
  List<_CalendarTransaction>? _realizedCalendarTransactionsCache;

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  void _ensureCalendarCache() {
    if (_allCalendarTransactionsCache != null) return;

    final refDay = _dateOnly(_chartReferenceDate);
    final transactions = TutorSettlementDummyData.build(
      asOf: _chartReferenceDate,
    ).map(_CalendarTransaction.fromDummy).toList();

    final byDay = <String, List<_CalendarTransaction>>{};
    for (final tx in transactions) {
      (byDay[_dayKey(tx.date)] ??= []).add(tx);
    }

    _allCalendarTransactionsCache = transactions;
    _transactionsByDayCache = byDay;
    _realizedCalendarTransactionsCache = transactions
        .where(
          (tx) =>
              !tx.filledFromPriorYear && !_dateOnly(tx.date).isAfter(refDay),
        )
        .toList();
  }

  List<_CalendarTransaction> get _calendarTransactions {
    _ensureCalendarCache();
    return _allCalendarTransactionsCache!;
  }

  List<_CalendarTransaction> get _realizedCalendarTransactions {
    _ensureCalendarCache();
    return _realizedCalendarTransactionsCache!;
  }

  Iterable<_CalendarTransaction> get _depositTransactions =>
      _calendarTransactions.where((tx) => tx.isDeposit);

  int _sumDeposits(Iterable<_CalendarTransaction> transactions) {
    return transactions.fold<int>(0, (sum, tx) => sum + tx.amount);
  }

  DateTime get _weekStart {
    final date = _chartReferenceDate;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  List<int> get _weeklyChartAmounts {
    final weekStart = _weekStart;
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return _sumDeposits(
        _depositTransactions.where((tx) => _isSameDay(tx.date, day)),
      );
    });
  }

  List<int> get _monthlyChartAmounts {
    final year = _chartReferenceDate.year;
    final month = _chartReferenceDate.month;
    return List.generate(4, (weekIndex) {
      final startDay = weekIndex * 7 + 1;
      final endDay = math.min((weekIndex + 1) * 7, 31);
      return _sumDeposits(
        _depositTransactions.where(
          (tx) =>
              tx.date.year == year &&
              tx.date.month == month &&
              tx.date.day >= startDay &&
              tx.date.day <= endDay,
        ),
      );
    });
  }

  List<int> get _yearlyChartAmounts {
    final year = _chartReferenceDate.year;
    return List.generate(12, (index) {
      final month = index + 1;
      return _sumDeposits(
        _depositTransactions.where(
          (tx) => tx.date.year == year && tx.date.month == month,
        ),
      );
    });
  }

  int get _withdrawableBalance {
    return _realizedCalendarTransactions.fold<int>(
      0,
      (sum, tx) => sum + tx.amount,
    );
  }

  int get _lastMonthDepositTotal {
    final ref = _chartReferenceDate;
    final lastMonth = ref.month == 1 ? 12 : ref.month - 1;
    final lastYear = ref.month == 1 ? ref.year - 1 : ref.year;
    return _sumDeposits(
      _depositTransactions.where(
        (tx) => tx.date.year == lastYear && tx.date.month == lastMonth,
      ),
    );
  }

  int get _lastMonthLessonCount {
    final ref = _chartReferenceDate;
    final lastMonth = ref.month == 1 ? 12 : ref.month - 1;
    final lastYear = ref.month == 1 ? ref.year - 1 : ref.year;
    return _depositTransactions
        .where((tx) => tx.date.year == lastYear && tx.date.month == lastMonth)
        .length;
  }

  _ChartPeriod _chartPeriod = _ChartPeriod.weekly;
  _HistoryFilter _historyFilter = _HistoryFilter.all;
  int _historyPageIndex = 0;

  List<int> get _currentChartAmounts {
    switch (_chartPeriod) {
      case _ChartPeriod.weekly:
        return _weeklyChartAmounts;
      case _ChartPeriod.monthly:
        return _monthlyChartAmounts;
      case _ChartPeriod.yearly:
        return _yearlyChartAmounts;
    }
  }

  List<String> get _currentChartLabels {
    switch (_chartPeriod) {
      case _ChartPeriod.weekly:
        return _weekLabels;
      case _ChartPeriod.monthly:
        return ['1주', '2주', '3주', '4주'];
      case _ChartPeriod.yearly:
        return _yearLabels;
    }
  }

  String get _chartTotalLabel {
    switch (_chartPeriod) {
      case _ChartPeriod.weekly:
        return '이번 주 총 수익';
      case _ChartPeriod.monthly:
        return '이번 달 총 수익';
      case _ChartPeriod.yearly:
        return '올해 총 수익';
    }
  }

  int get _chartTotal =>
      _currentChartAmounts.fold<int>(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildWithdrawCard(),
              const SizedBox(height: 12),
              _buildLastMonthCard(),
              const SizedBox(height: 20),
              _buildChartSection(),
              const SizedBox(height: 24),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '정산',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _labelColor,
            ),
          ),
        ),
        IconButton(
          onPressed: _showCalendarPopup,
          icon: const Icon(
            Icons.calendar_today_outlined,
            size: 24,
            color: _labelColor,
          ),
        ),
      ],
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatKoreanYearMonth(DateTime month) =>
      '${month.year}년 ${month.month.toString().padLeft(2, '0')}월';

  String _formatKoreanDayTitle(DateTime date) =>
      '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 '
      '${date.day.toString().padLeft(2, '0')}일';

  List<_CalendarTransaction> _transactionsOnDay(DateTime day) {
    _ensureCalendarCache();
    return List<_CalendarTransaction>.from(
      _transactionsByDayCache![_dayKey(day)] ?? const [],
    );
  }

  int _dayDepositTotal(DateTime day) => _transactionsOnDay(day)
      .where((t) => t.isDeposit)
      .fold<int>(0, (sum, t) => sum + t.amount);

  int _dayWithdrawalTotal(DateTime day) => _transactionsOnDay(day)
      .where((t) => !t.isDeposit)
      .fold<int>(0, (sum, t) => sum + t.amount);

  String _formatSignedWon(int amount) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${_formatWon(amount.abs())}';
  }

  static const _calendarCellHeight = 80.0;

  static const _calendarWeekdayHeaderHeight = 28.0;
  static const _calendarYearPickerBodyHeight = 280.0;
  static const _calendarMonthPickerBodyHeight = 200.0;
  static const _calendarDetailExpandLimit = 4;
  static const _calendarDetailHeaderSectionHeight = 41.0;
  static const _calendarDetailRowBlockHeight = 50.0;
  static const _calendarDetailListVerticalPadding = 20.0;
  static const _calendarDetailMaxPanelHeight = 260.0;

  /// 개발 단계용 넉넉한 연도 범위. 출시 시 입출금 min/max 연도 기준으로 좁히면 됨.
  static const _calendarYearLookback = 10;
  static const _calendarYearLookahead = 5;
  static const _calendarDialogMaxWidth = 800.0;

  /// 달력 다이얼로그·그리드 좌우 여백 (좁은 화면일수록 넓게).
  static double _calendarDialogInsetHorizontal(double screenWidth) {
    if (screenWidth < 360) return 24;
    if (screenWidth < 420) return 20;
    return 16;
  }

  static double _calendarContentPaddingHorizontal(double screenWidth) {
    if (screenWidth < 360) return 12;
    if (screenWidth < 420) return 10;
    return 8;
  }

  (int, int) _calendarYearRange() {
    final nowYear = DateTime.now().year;
    var minYear = nowYear - _calendarYearLookback;
    var maxYear = nowYear + _calendarYearLookahead;

    for (final t in _calendarTransactions) {
      if (t.date.year < minYear) minYear = t.date.year - 1;
      if (t.date.year > maxYear) maxYear = t.date.year + 1;
    }
    return (minYear, maxYear);
  }

  double _calendarBodyHeight(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = DateTime(month.year, month.month, 1).weekday - 1;
    final rowCount = ((leadingEmpty + daysInMonth) / 7).ceil();
    return _calendarWeekdayHeaderHeight + rowCount * _calendarCellHeight;
  }

  int _yearPickerIndex(int year, int firstYear, int lastYear) {
    return (year - firstYear).clamp(0, lastYear - firstYear);
  }

  double? _calendarDetailPanelHeight(List<_CalendarTransaction> transactions) {
    if (transactions.isEmpty) return null;
    if (transactions.length <= _calendarDetailExpandLimit) {
      return _calendarDetailHeaderSectionHeight +
          _calendarDetailListVerticalPadding +
          transactions.length * _calendarDetailRowBlockHeight +
          4;
    }
    return _calendarDetailMaxPanelHeight;
  }

  void _showCalendarPopup() {
    _ensureCalendarCache();
    final today = _dateOnly(_chartReferenceDate);
    final (firstYear, lastYear) = _calendarYearRange();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        DateTime? detailDate;
        var displayMonth = DateTime(today.year, today.month);
        var pickerStep = _CalendarPickerStep.dayGrid;
        int? pendingYear;
        final yearScrollController = FixedExtentScrollController(
          initialItem: _yearPickerIndex(today.year, firstYear, lastYear),
        );

        final screenSize = MediaQuery.of(dialogContext).size;
        final insetH = _calendarDialogInsetHorizontal(screenSize.width);
        final contentPadH = _calendarContentPaddingHorizontal(screenSize.width);
        final dialogWidth = math.min(
          screenSize.width - insetH * 2,
          _calendarDialogMaxWidth,
        );
        final maxDialogHeight = screenSize.height * 0.92;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: insetH, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              void selectDay(DateTime day) {
                setDialogState(() => detailDate = _dateOnly(day));
              }

              void changeMonth(int delta) {
                setDialogState(() {
                  displayMonth = DateTime(
                    displayMonth.year,
                    displayMonth.month + delta,
                  );
                });
              }

              void jumpYearWheel(int year) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (yearScrollController.hasClients) {
                    yearScrollController.jumpToItem(
                      _yearPickerIndex(year, firstYear, lastYear),
                    );
                  }
                });
              }

              final showDetail =
                  detailDate != null && pickerStep == _CalendarPickerStep.dayGrid;
              final selectedDayTransactions = showDetail
                  ? (_transactionsOnDay(detailDate!)
                    ..sort((a, b) => a.date.compareTo(b.date)))
                  : <_CalendarTransaction>[];

              final bodyHeight = switch (pickerStep) {
                _CalendarPickerStep.dayGrid =>
                  _calendarBodyHeight(displayMonth),
                _CalendarPickerStep.yearPick => _calendarYearPickerBodyHeight,
                _CalendarPickerStep.monthPick => _calendarMonthPickerBodyHeight,
              };

              Widget body;
              switch (pickerStep) {
                case _CalendarPickerStep.dayGrid:
                  body = _buildCalendarDayGrid(
                    displayMonth: displayMonth,
                    selectedDate: detailDate,
                    onDaySelected: selectDay,
                  );
                case _CalendarPickerStep.yearPick:
                  body = _buildCalendarYearPicker(
                    firstYear: firstYear,
                    lastYear: lastYear,
                    selectedYear: pendingYear ?? displayMonth.year,
                    scrollController: yearScrollController,
                    bodyHeight: bodyHeight,
                    onYearChanged: (year) =>
                        setDialogState(() => pendingYear = year),
                    onConfirm: () => setDialogState(
                      () => pickerStep = _CalendarPickerStep.monthPick,
                    ),
                    confirmLabel:
                        '${pendingYear ?? displayMonth.year}년 월 선택',
                  );
                case _CalendarPickerStep.monthPick:
                  body = _buildCalendarMonthPicker(
                    selectedMonth: displayMonth.month,
                    bodyHeight: bodyHeight,
                    onMonthSelected: (month) => setDialogState(() {
                      displayMonth = DateTime(pendingYear!, month);
                      pickerStep = _CalendarPickerStep.dayGrid;
                      pendingYear = null;
                    }),
                  );
              }

              final dialogContent = Padding(
                padding: EdgeInsets.symmetric(horizontal: contentPadH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 0, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '입출금 달력',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _labelColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pickerStep == _CalendarPickerStep.dayGrid)
                      _buildCalendarMonthHeader(
                        title: _formatKoreanYearMonth(displayMonth),
                        onTitleTap: () {
                          final year = displayMonth.year;
                          setDialogState(() {
                            pickerStep = _CalendarPickerStep.yearPick;
                            pendingYear = year;
                          });
                          jumpYearWheel(year);
                        },
                        onPrevious: () => changeMonth(-1),
                        onNext: () => changeMonth(1),
                      )
                    else if (pickerStep == _CalendarPickerStep.yearPick)
                      _buildCalendarStepHeader(
                        title: '연도 선택',
                        onBack: () => setDialogState(
                          () => pickerStep = _CalendarPickerStep.dayGrid,
                        ),
                      )
                    else
                      _buildCalendarStepHeader(
                        title: '${pendingYear ?? displayMonth.year}년 월 선택',
                        onBack: () {
                          final year = pendingYear ?? displayMonth.year;
                          setDialogState(() {
                            pickerStep = _CalendarPickerStep.yearPick;
                          });
                          jumpYearWheel(year);
                        },
                      ),
                    SizedBox(height: bodyHeight, child: body),
                    if (showDetail) ...[
                      const SizedBox(height: 8),
                      _buildCalendarDetailPanel(
                        date: detailDate!,
                        transactions: selectedDayTransactions,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              );

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: maxDialogHeight,
                ),
                child: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    child: dialogContent,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCalendarMonthHeader({
    required String title,
    required VoidCallback onTitleTap,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, size: 22, color: _labelColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTitleTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _labelColor,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 20, color: _hintColor),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 22, color: _labelColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Widget _buildCalendarStepHeader({
    required String title,
    required VoidCallback onBack,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _labelColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _labelColor,
            ),
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildCalendarDayGrid({
    required DateTime displayMonth,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDaySelected,
  }) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final today = _dateOnly(_chartReferenceDate);
    final cellCount = leadingEmpty + daysInMonth;
    final rowCount = (cellCount / 7).ceil();
    const cellHeight = _calendarCellHeight;
    final gridHeight = rowCount * cellHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _calendarWeekdayHeaderHeight,
          child: Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _hintColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            mainAxisExtent: cellHeight,
          ),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox.shrink();

            final day = index - leadingEmpty + 1;
            final date = DateTime(displayMonth.year, displayMonth.month, day);
            final isSelected =
                selectedDate != null && _isSameDay(date, selectedDate);
            final isToday = _isSameDay(date, today);
            final depositTotal = _dayDepositTotal(date);
            final withdrawalTotal = _dayWithdrawalTotal(date);

            return GestureDetector(
              onTap: () => onDaySelected(date),
              child: SizedBox(
                height: cellHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.primaryBlue,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryBlue
                                  : _labelColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (depositTotal > 0)
                      Text(
                        _formatSignedWon(depositTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _incomeColor,
                          height: 1.1,
                        ),
                      ),
                    if (withdrawalTotal < 0) ...[
                      if (depositTotal > 0) const SizedBox(height: 2),
                      Text(
                        _formatSignedWon(withdrawalTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _expenseColor,
                          height: 1.1,
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarYearPicker({
    required int firstYear,
    required int lastYear,
    required int selectedYear,
    required FixedExtentScrollController scrollController,
    required double bodyHeight,
    required ValueChanged<int> onYearChanged,
    required VoidCallback onConfirm,
    required String confirmLabel,
  }) {
    final yearCount = lastYear - firstYear + 1;
    const buttonHeight = 40.0;

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
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 40,
                  diameterRatio: 1.4,
                  perspective: 0.003,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    onYearChanged(firstYear + index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: yearCount,
                    builder: (context, index) {
                      final year = firstYear + index;
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
                                ? AppColors.primaryBlue
                                : _hintColor,
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
              height: buttonHeight,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarMonthPicker({
    required int selectedMonth,
    required double bodyHeight,
    required ValueChanged<int> onMonthSelected,
  }) {
    const monthLabels = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];

    const rowCount = 3;
    const columnCount = 4;
    const horizontalPadding = 8.0;
    const verticalPadding = 4.0;
    const mainSpacing = 4.0;
    const crossSpacing = 4.0;

    return SizedBox(
      height: bodyHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = (constraints.maxHeight -
                  verticalPadding * 2 -
                  mainSpacing * (rowCount - 1)) /
              rowCount;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: mainSpacing,
              crossAxisSpacing: crossSpacing,
              mainAxisExtent: cellHeight,
            ),
            itemCount: monthLabels.length,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == selectedMonth;
              return GestureDetector(
                onTap: () => onMonthSelected(month),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthLabels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _labelColor,
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

  Widget _buildCalendarDetailPanel({
    required DateTime date,
    required List<_CalendarTransaction> transactions,
  }) {
    final panelHeight = _calendarDetailPanelHeight(transactions);
    final useScroll = transactions.length > _calendarDetailExpandLimit;
    final isEmpty = transactions.isEmpty;

    Widget body;
    if (isEmpty) {
      body = const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: Text(
          '해당 날짜의 입출금 내역이 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _hintColor),
        ),
      );
    } else if (useScroll) {
      body = Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) =>
              _buildCalendarDetailRow(transactions[index]),
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < transactions.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _buildCalendarDetailRow(transactions[i]),
            ],
          ],
        ),
      );
    }

    return Container(
      height: panelHeight,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Column(
        mainAxisSize:
            panelHeight == null ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              _formatKoreanDayTitle(date),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _labelColor,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF0)),
          body,
        ],
      ),
    );
  }

  Widget _buildCalendarDetailRow(_CalendarTransaction item) {
    final isDeposit = item.isDeposit;
    final amountColor = isDeposit ? _incomeColor : _expenseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.fullDateTimeLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _labelColor,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatSignedWon(item.amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                '출금 가능 금액',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatWon(_withdrawableBalance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '출금 신청',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastMonthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '저번 달 수입',
                style: TextStyle(fontSize: 14, color: _hintColor),
              ),
              const Spacer(),
              Text(
                _formatSignedWon(_lastMonthDepositTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _incomeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '총 수업 수',
                      style: TextStyle(fontSize: 13, color: _hintColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_lastMonthLessonCount회',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '평균 수업 시간',
                        style: TextStyle(fontSize: 13, color: _hintColor),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '45분',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '정산 현황',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _labelColor,
                ),
              ),
            ),
            _buildPeriodChip('주간', _chartPeriod == _ChartPeriod.weekly, () {
              setState(() => _chartPeriod = _ChartPeriod.weekly);
            }),
            const SizedBox(width: 6),
            _buildPeriodChip('월간', _chartPeriod == _ChartPeriod.monthly, () {
              setState(() => _chartPeriod = _ChartPeriod.monthly);
            }),
            const SizedBox(width: 6),
            _buildPeriodChip('연간', _chartPeriod == _ChartPeriod.yearly, () {
              setState(() => _chartPeriod = _ChartPeriod.yearly);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              _buildBarChart(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _chartTotalLabel,
                  style: const TextStyle(fontSize: 13, color: _hintColor),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatWon(_chartTotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : const Color(0xFFF0F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final amounts = _currentChartAmounts;
    final labels = _currentChartLabels;
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    const chartHeight = 120.0;
    final labelFontSize = _chartPeriod == _ChartPeriod.yearly ? 10.0 : 12.0;

    return SizedBox(
      height: chartHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(amounts.length, (index) {
          final barHeight =
              maxAmount == 0 ? 0.0 : (amounts[index] / maxAmount) * chartHeight;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _chartPeriod == _ChartPeriod.yearly ? 1 : 3,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barHeight.clamp(12, chartHeight),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: TextStyle(fontSize: labelFontSize, color: _hintColor),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _setHistoryFilter(_HistoryFilter filter) {
    setState(() {
      _historyFilter = filter;
      _historyPageIndex = 0;
    });
  }

  Widget _buildHistoryPagination(int pageCount) {
    if (pageCount <= 1) return const SizedBox.shrink();

    final canGoPrev = _historyPageIndex > 0;
    final canGoNext = _historyPageIndex < pageCount - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoPrev
                ? () => setState(() => _historyPageIndex -= 1)
                : null,
            icon: Icon(
              Icons.chevron_left,
              size: 22,
              color: canGoPrev ? _labelColor : _hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${_historyPageIndex + 1} / $pageCount',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
          IconButton(
            onPressed: canGoNext
                ? () => setState(() => _historyPageIndex += 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoNext ? _labelColor : _hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final pageCount = _historyPageCount;
    final pagedItems = _pagedSettlementHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '정산 내역',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPeriodChip('전체', _historyFilter == _HistoryFilter.all, () {
              _setHistoryFilter(_HistoryFilter.all);
            }),
            const SizedBox(width: 6),
            _buildPeriodChip('입금', _historyFilter == _HistoryFilter.deposit, () {
              _setHistoryFilter(_HistoryFilter.deposit);
            }),
            const SizedBox(width: 6),
            _buildPeriodChip(
              '출금',
              _historyFilter == _HistoryFilter.withdrawal,
              () {
                _setHistoryFilter(_HistoryFilter.withdrawal);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pagedItems.isEmpty)
          const Text(
            '표시할 정산 내역이 없습니다.',
            style: TextStyle(fontSize: 13, color: _hintColor),
          )
        else ...[
          for (final item in pagedItems) ...[
            _buildHistoryCard(item),
            const SizedBox(height: 10),
          ],
          _buildHistoryPagination(pageCount),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(_SettlementHistoryItem item) {
    final color = item.isIncome ? _incomeColor : _expenseColor;
    final amountText = item.isIncome
        ? '+${_formatWon(item.amount)}'
        : '-${_formatWon(item.amount.abs())}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _labelColor,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatFullDateTime(item.date),
                style: const TextStyle(fontSize: 12, color: _hintColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWon(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$buffer원';
  }
}
