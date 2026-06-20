import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/utils/won_format_util.dart';
import 'package:ieum/core/utils/date_format_util.dart';
import 'package:ieum/features/tutor/data/settlement_models.dart';
import 'package:ieum/features/tutor/providers/settlement_provider.dart';

enum _ChartPeriod { weekly, monthly, yearly }

enum _HistoryFilter { all, deposit, withdrawal }

enum _CalendarPickerStep { dayGrid, yearPick, monthPick }

/// 입출금 달력 — 화면 크기별 글자·셀 스케일
class _CalendarLayout {
  const _CalendarLayout({
    required this.cellHeight,
    required this.weekdayHeaderHeight,
    required this.dayFontSize,
    required this.weekdayFontSize,
    required this.amountFontSize,
    required this.amountCellWidth,
    required this.amountSlotHeight,
    required this.amountLineGap,
    required this.dayBadgeSize,
    required this.monthTitleFontSize,
    required this.detailTimeFontSize,
    required this.detailPanelMaxHeight,
  });

  final double cellHeight;
  final double weekdayHeaderHeight;
  final double dayFontSize;
  final double weekdayFontSize;
  final double amountFontSize;
  final double amountCellWidth;
  final double amountSlotHeight;
  final double amountLineGap;
  final double dayBadgeSize;
  final double monthTitleFontSize;
  final double detailTimeFontSize;
  final double detailPanelMaxHeight;

  static double _sheetPaddingHorizontal(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 420) return 14;
    return 12;
  }

  static double _dayCellInnerWidth(Size size) {
    final pad = _sheetPaddingHorizontal(size.width);
    return (size.width - pad * 2) / 7;
  }

  static double _amountSlotHeight(double fontSize) => fontSize * 1.08;

  /// 셀 너비·화면 크기에 따라 입출금 글자 크기 연속 스케일
  static double _scaledAmountFontSize({
    required Size screenSize,
    required double cellWidth,
    required bool detailVisible,
  }) {
    const refCellWidth = 52.0;
    const refFontSize = 10.0;

    // 셀 안에 "+123,456원"이 들어가도록 너비 비례
    final cellBased = cellWidth * (refFontSize / refCellWidth);

    // 기기 가로(390 기준): 작은 폰 축소 · 큰 폰·태블릿 확대
    final deviceScale = (screenSize.width / 390).clamp(0.78, 1.22);

    // 세로가 낮거나 상세 패널이 열리면 한 단계 축소
    final heightScale = switch (screenSize.height) {
      < 640 => 0.88,
      < 720 => detailVisible ? 0.9 : 0.95,
      _ => detailVisible && screenSize.height < 800 ? 0.94 : 1.0,
    };

    return (cellBased * deviceScale * heightScale).clamp(6.0, 12.5);
  }

  factory _CalendarLayout.fromScreen(Size size, {required bool detailVisible}) {
    final h = size.height;
    final w = size.width;
    final amountCellWidth = _dayCellInnerWidth(size);
    final tight = detailVisible && h < 740;
    final compact = h < 720 || w < 380 || tight;
    final tiny = h < 640 || w < 340 || (detailVisible && h < 680);

    if (tiny) {
      final amountFontSize = _scaledAmountFontSize(
        screenSize: size,
        cellWidth: amountCellWidth,
        detailVisible: detailVisible,
      );
      return _CalendarLayout(
        cellHeight: detailVisible ? 60 : 62,
        weekdayHeaderHeight: 22,
        dayFontSize: 16,
        weekdayFontSize: 11,
        amountFontSize: amountFontSize,
        amountCellWidth: amountCellWidth,
        amountSlotHeight: _amountSlotHeight(amountFontSize),
        amountLineGap: 1,
        dayBadgeSize: 28,
        monthTitleFontSize: 14,
        detailTimeFontSize: 10,
        detailPanelMaxHeight: h * 0.36,
      );
    }
    if (compact) {
      final amountFontSize = _scaledAmountFontSize(
        screenSize: size,
        cellWidth: amountCellWidth,
        detailVisible: detailVisible,
      );
      return _CalendarLayout(
        cellHeight: detailVisible ? 68 : 70,
        weekdayHeaderHeight: 24,
        dayFontSize: 17,
        weekdayFontSize: 12,
        amountFontSize: amountFontSize,
        amountCellWidth: amountCellWidth,
        amountSlotHeight: _amountSlotHeight(amountFontSize),
        amountLineGap: 1.5,
        dayBadgeSize: 30,
        monthTitleFontSize: 15,
        detailTimeFontSize: 11,
        detailPanelMaxHeight: h * 0.38,
      );
    }
    final amountFontSize = _scaledAmountFontSize(
      screenSize: size,
      cellWidth: amountCellWidth,
      detailVisible: detailVisible,
    );
    return _CalendarLayout(
      cellHeight: detailVisible ? 72 : 80,
      weekdayHeaderHeight: 28,
      dayFontSize: 19,
      weekdayFontSize: 14,
      amountFontSize: amountFontSize,
      amountCellWidth: amountCellWidth,
      amountSlotHeight: _amountSlotHeight(amountFontSize),
      amountLineGap: 2,
      dayBadgeSize: 34,
      monthTitleFontSize: 16,
      detailTimeFontSize: 12,
      detailPanelMaxHeight: 260,
    );
  }
}

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

  String get fullDateTimeLabel => formatDotDateTime(date);
}

class TutorSettlementScreen extends ConsumerStatefulWidget {
  const TutorSettlementScreen({super.key});

  @override
  ConsumerState<TutorSettlementScreen> createState() =>
      _TutorSettlementScreenState();
}

class _TutorSettlementScreenState extends ConsumerState<TutorSettlementScreen> {
  /// 포인트 컬러(#BFA2DB)와 어울리는 입금(녹색)·출금(붉은) 톤
  static const _incomeColor = AppColors.incomeGreen;
  static const _expenseColor = Color(0xFFD46878);

  ColorScheme _scheme(BuildContext context) => Theme.of(context).colorScheme;

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

  /// 차트·잔액 계산 기준일 (오늘).
  DateTime get _chartReferenceDate => DateTime.now();

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

  /// 백엔드에서 받아 변환한 거래 목록 (provider 데이터로 채워짐).
  List<TutorSettlementCalendarTransaction>? _sourceTransactions;

  /// 상태 뱃지·출금 요청에 쓰는 원본 정산 건 목록.
  List<SettlementResponse> _records = const [];
  SettlementSummaryResponse? _summary;

  /// provider가 새 데이터를 내려주면 캐시를 비우고 소스를 교체한다.
  void _applyData(TutorSettlementData data) {
    if (identical(_sourceTransactions, data.transactions)) return;
    _sourceTransactions = data.transactions;
    _records = data.records;
    _summary = data.summary;
    _allCalendarTransactionsCache = null;
    _transactionsByDayCache = null;
    _realizedCalendarTransactionsCache = null;
  }

  List<_CalendarTransaction>? _allCalendarTransactionsCache;
  Map<String, List<_CalendarTransaction>>? _transactionsByDayCache;
  List<_CalendarTransaction>? _realizedCalendarTransactionsCache;

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  void _ensureCalendarCache() {
    if (_allCalendarTransactionsCache != null) return;

    final refDay = _dateOnly(_chartReferenceDate);
    final transactions =
        (_sourceTransactions ?? const <TutorSettlementCalendarTransaction>[])
            .map(_CalendarTransaction.fromDummy)
            .toList();

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
    final async = ref.watch(settlementDataProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, error),
          data: (data) {
            _applyData(data);
            return _buildContent(context);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildWithdrawCard(context),
          const SizedBox(height: 12),
          _buildSummaryCard(context),
          const SizedBox(height: 12),
          _buildLastMonthCard(context),
          const SizedBox(height: 20),
          _buildChartSection(context),
          const SizedBox(height: 24),
          _buildHistorySection(context),
          const SizedBox(height: 24),
          _buildSettlementRecordsSection(context),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final scheme = _scheme(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              '정산 정보를 불러오지 못했습니다.',
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(settlementDataProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = _scheme(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '정산',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: _showCalendarBottomSheet,
          icon: Icon(
            Icons.calendar_today_outlined,
            size: 24,
            color: scheme.onSurface,
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
    return '$sign${formatWon(amount.abs())}';
  }

  static const _calendarYearPickerBodyHeight = 280.0;
  static const _calendarMonthPickerBodyHeight = 200.0;
  static const _calendarDetailExpandLimit = 4;

  /// 개발 단계용 넉넉한 연도 범위. 출시 시 입출금 min/max 연도 기준으로 좁히면 됨.
  static const _calendarYearLookback = 10;
  static const _calendarYearLookahead = 5;
  static const _calendarDetailAmountWidth = 92.0;

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

  double _calendarBodyHeight(DateTime month, _CalendarLayout layout) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = DateTime(month.year, month.month, 1).weekday - 1;
    final rowCount = ((leadingEmpty + daysInMonth) / 7).ceil();
    return layout.weekdayHeaderHeight + rowCount * layout.cellHeight;
  }

  int _yearPickerIndex(int year, int firstYear, int lastYear) {
    return (year - firstYear).clamp(0, lastYear - firstYear);
  }

  double? _calendarDetailPanelHeight(
    List<_CalendarTransaction> transactions,
    _CalendarLayout layout,
  ) {
    if (transactions.isEmpty) return null;
    if (transactions.length <= _calendarDetailExpandLimit) {
      // 행 높이는 시각·폰트에 따라 달라져 고정값 대신 내용 높이에 맡김
      return null;
    }
    return layout.detailPanelMaxHeight;
  }

  void _showCalendarBottomSheet() {
    _ensureCalendarCache();
    final today = _dateOnly(_chartReferenceDate);
    final (firstYear, lastYear) = _calendarYearRange();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        DateTime? detailDate;
        var displayMonth = DateTime(today.year, today.month);
        var pickerStep = _CalendarPickerStep.dayGrid;
        int? pendingYear;
        final yearScrollController = FixedExtentScrollController(
          initialItem: _yearPickerIndex(today.year, firstYear, lastYear),
        );

        final screenSize = MediaQuery.sizeOf(sheetContext);
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final contentPadH =
            _CalendarLayout._sheetPaddingHorizontal(screenSize.width);
        final maxSheetHeight = screenSize.height * 0.92;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void selectDay(DateTime day) {
              setSheetState(() => detailDate = _dateOnly(day));
            }

            void changeMonth(int delta) {
              setSheetState(() {
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

            final layout = _CalendarLayout.fromScreen(
              screenSize,
              detailVisible: showDetail,
            );

            final bodyHeight = switch (pickerStep) {
              _CalendarPickerStep.dayGrid =>
                _calendarBodyHeight(displayMonth, layout),
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
                  layout: layout,
                );
              case _CalendarPickerStep.yearPick:
                body = _buildCalendarYearPicker(
                  firstYear: firstYear,
                  lastYear: lastYear,
                  selectedYear: pendingYear ?? displayMonth.year,
                  scrollController: yearScrollController,
                  bodyHeight: bodyHeight,
                  onYearChanged: (year) =>
                      setSheetState(() => pendingYear = year),
                  onConfirm: () => setSheetState(
                    () => pickerStep = _CalendarPickerStep.monthPick,
                  ),
                  confirmLabel:
                      '${pendingYear ?? displayMonth.year}년 월 선택',
                );
              case _CalendarPickerStep.monthPick:
                body = _buildCalendarMonthPicker(
                  selectedMonth: displayMonth.month,
                  bodyHeight: bodyHeight,
                  onMonthSelected: (month) => setSheetState(() {
                    displayMonth = DateTime(pendingYear!, month);
                    pickerStep = _CalendarPickerStep.dayGrid;
                    pendingYear = null;
                  }),
                );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
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
                        padding: EdgeInsets.symmetric(horizontal: contentPadH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '입출금 달력',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(sheetContext),
                                    icon: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (pickerStep == _CalendarPickerStep.dayGrid)
                              _buildCalendarMonthHeader(
                                title: _formatKoreanYearMonth(displayMonth),
                                titleFontSize: layout.monthTitleFontSize,
                                onTitleTap: () {
                                  final year = displayMonth.year;
                                  setSheetState(() {
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
                                onBack: () => setSheetState(
                                  () => pickerStep = _CalendarPickerStep.dayGrid,
                                ),
                              )
                            else
                              _buildCalendarStepHeader(
                                title:
                                    '${pendingYear ?? displayMonth.year}년 월 선택',
                                onBack: () {
                                  final year = pendingYear ?? displayMonth.year;
                                  setSheetState(() {
                                    pickerStep = _CalendarPickerStep.yearPick;
                                  });
                                  jumpYearWheel(year);
                                },
                              ),
                            SizedBox(height: bodyHeight, child: body),
                            if (showDetail) ...[
                              const SizedBox(height: 10),
                              _buildCalendarDetailPanel(
                                date: detailDate!,
                                transactions: selectedDayTransactions,
                                layout: layout,
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarMonthHeader({
    required String title,
    required double titleFontSize,
    required VoidCallback onTitleTap,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: Icon(
            Icons.chevron_left,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: titleFontSize + 4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(
            Icons.chevron_right,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
              color: Theme.of(context).colorScheme.onSurface,
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
    required _CalendarLayout layout,
  }) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final today = _dateOnly(_chartReferenceDate);
    final cellCount = leadingEmpty + daysInMonth;
    final rowCount = (cellCount / 7).ceil();
    final cellHeight = layout.cellHeight;
    final gridHeight = rowCount * cellHeight;
    final topGap = layout.cellHeight < 70 ? 2.0 : 3.0;
    final amountTopGap = layout.cellHeight < 70 ? 1.0 : 2.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: layout.weekdayHeaderHeight,
          child: Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: layout.weekdayFontSize,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                  children: [
                    SizedBox(height: topGap),
                    Container(
                      width: layout.dayBadgeSize,
                      height: layout.dayBadgeSize,
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
                          fontSize: layout.dayFontSize,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.onPrimaryFill(
                                  Theme.of(context).brightness,
                                )
                              : isToday
                                  ? AppColors.primaryBlue
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: amountTopGap),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (depositTotal > 0)
                              _buildCalendarDayAmountLine(
                                layout: layout,
                                text: _formatSignedWon(depositTotal),
                                color: _incomeColor,
                              ),
                            if (depositTotal > 0 && withdrawalTotal < 0)
                              SizedBox(height: layout.amountLineGap),
                            if (withdrawalTotal < 0)
                              _buildCalendarDayAmountLine(
                                layout: layout,
                                text: _formatSignedWon(withdrawalTotal),
                                color: _expenseColor,
                              ),
                          ],
                        ),
                      ),
                    ),
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

  /// 달력 셀 입·출금 한 줄 (있는 것만 위에서부터 표시)
  Widget _buildCalendarDayAmountLine({
    required _CalendarLayout layout,
    required String text,
    required Color color,
  }) {
    return SizedBox(
      height: layout.amountSlotHeight,
      width: layout.amountCellWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: layout.amountFontSize,
            fontWeight: FontWeight.w500,
            color: color,
            height: 1.0,
            letterSpacing: -0.3,
          ),
        ),
      ),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.18),
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
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                  foregroundColor: AppColors.onPrimaryFill(
                    Theme.of(context).brightness,
                  ),
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
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthLabels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
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
    required _CalendarLayout layout,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final panelHeight = _calendarDetailPanelHeight(transactions, layout);
    final useScroll = transactions.length > _calendarDetailExpandLimit;
    final isEmpty = transactions.isEmpty;

    Widget body;
    if (isEmpty) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: Text(
          '해당 날짜의 입출금 내역이 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      );
    } else if (useScroll) {
      body = ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: transactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) => _buildCalendarDetailRow(
          transactions[index],
          timeFontSize: layout.detailTimeFontSize,
          amountFontSize: layout.detailTimeFontSize + 1,
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
              _buildCalendarDetailRow(
                transactions[i],
                timeFontSize: layout.detailTimeFontSize,
                amountFontSize: layout.detailTimeFontSize + 1,
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      height: panelHeight,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outline),
          if (useScroll && panelHeight != null) Expanded(child: body) else body,
        ],
      ),
    );
  }

  Widget _buildCalendarDetailRow(
    _CalendarTransaction item, {
    required double timeFontSize,
    required double amountFontSize,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDeposit = item.isDeposit;
    final amountColor = isDeposit ? _incomeColor : _expenseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.fullDateTimeLabel,
              style: TextStyle(
                fontSize: timeFontSize,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _calendarDetailAmountWidth,
            child: Text(
              _formatSignedWon(item.amount),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: amountFontSize,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawCard(BuildContext context) {
    final scheme = _scheme(context);
    final withdrawableCount = _records
        .where((r) => r.status == SettlementStatus.calculated)
        .length;
    final withdrawableAmount = _records
        .where((r) => r.status == SettlementStatus.calculated)
        .fold<int>(0, (sum, r) => sum + r.tutorAmount);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                '출금 가능 금액',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatWon(withdrawableAmount),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (withdrawableCount > 0)
            Text(
              '정산 대기 $withdrawableCount건',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: withdrawableCount > 0 ? _onBulkWithdraw : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                withdrawableCount > 0
                    ? '전체 출금 신청 ($withdrawableCount건)'
                    : '출금 가능한 정산이 없습니다',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBulkWithdraw() async {
    final withdrawableCount = _records
        .where((r) => r.status == SettlementStatus.calculated)
        .length;
    final withdrawableAmount = _records
        .where((r) => r.status == SettlementStatus.calculated)
        .fold<int>(0, (sum, r) => sum + r.tutorAmount);

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '일괄 출금 요청',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '총 $withdrawableCount건의 정산을\n일괄 출금 요청합니다.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '출금 합계',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatWon(withdrawableAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('출금 요청'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ref
          .read(settlementRepositoryProvider)
          .requestBulkWithdraw(settlementTutorId);
      ref.invalidate(settlementDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.settlementCount}건 / ${formatWon(result.totalAmount)} 출금 요청 완료',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출금 요청 실패: $error')),
        );
      }
    }
  }

  Widget _buildLastMonthCard(BuildContext context) {
    final scheme = _scheme(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '저번 달 수입',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
          Divider(height: 1, color: scheme.outline),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 수업 수',
                      style:
                          TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_lastMonthLessonCount회',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
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
                    children: [
                      Text(
                        '평균 수업 시간',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '45분',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
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

  Widget _buildChartSection(BuildContext context) {
    final scheme = _scheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '정산 현황',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
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
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            children: [
              _buildBarChart(context),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _chartTotalLabel,
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formatWon(_chartTotal),
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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : scheme.surfaceContainerHighest,
          border: selected
              ? null
              : Border.all(color: scheme.outline, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final scheme = _scheme(context);
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
                    style: TextStyle(
                      fontSize: labelFontSize,
                      color: scheme.onSurfaceVariant,
                    ),
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

  Widget _buildHistoryPagination(BuildContext context, int pageCount) {
    if (pageCount <= 1) return const SizedBox.shrink();

    final scheme = _scheme(context);
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
              color: canGoPrev ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${_historyPageIndex + 1} / $pageCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: canGoNext
                ? () => setState(() => _historyPageIndex += 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoNext ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final scheme = _scheme(context);
    final pageCount = _historyPageCount;
    final pagedItems = _pagedSettlementHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정산 내역',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
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
          Text(
            '표시할 정산 내역이 없습니다.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          )
        else ...[
          for (final item in pagedItems) ...[
            _buildHistoryCard(context, item),
            const SizedBox(height: 10),
          ],
          _buildHistoryPagination(context, pageCount),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, _SettlementHistoryItem item) {
    final scheme = _scheme(context);
    final color = item.isIncome ? _incomeColor : _expenseColor;
    final amountText = item.isIncome
        ? '+${formatWon(item.amount)}'
        : '-${formatWon(item.amount.abs())}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
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
                formatDotDateTime(item.date),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 정산 요약 / 정산 건 목록 ──────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context) {
    final scheme = _scheme(context);
    final summary = _summary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          _buildSummaryItem(context, '총 정산액', summary?.totalAmount ?? 0),
          _buildSummaryDivider(scheme),
          _buildSummaryItem(context, '송금 완료', summary?.transferredAmount ?? 0),
          _buildSummaryDivider(scheme),
          _buildSummaryItem(context, '정산 대기', summary?.pendingAmount ?? 0),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, int amount) {
    final scheme = _scheme(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            formatWon(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider(ColorScheme scheme) => Container(
        width: 1,
        height: 32,
        color: scheme.outline,
      );

  /// 상태별 (라벨, 색).
  (String, Color) _statusBadge(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.calculated:
        return ('출금 가능', AppColors.primaryBlue);
      case SettlementStatus.pending:
        return ('송금 대기', const Color(0xFFE08E3C));
      case SettlementStatus.transferred:
        return ('송금 완료', _incomeColor);
      case SettlementStatus.failed:
        return ('실패', _expenseColor);
      case SettlementStatus.unknown:
        return ('알 수 없음', _scheme(context).onSurfaceVariant);
    }
  }

  Widget _buildSettlementRecordsSection(BuildContext context) {
    final scheme = _scheme(context);
    final records = [..._records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정산 관리',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          Text(
            '정산 건이 없습니다.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          )
        else
          for (final record in records) ...[
            _buildSettlementRecordCard(context, record),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildSettlementRecordCard(
    BuildContext context,
    SettlementResponse record,
  ) {
    final scheme = _scheme(context);
    final (badgeLabel, badgeColor) = _statusBadge(record.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '수업 #${record.lessonId}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatDotDateTime(record.createdAt),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                '+${formatWon(record.tutorAmount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _incomeColor,
                ),
              ),
            ],
          ),
          if (record.isWithdrawable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _onRequestWithdraw(record.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '출금 요청',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onRequestWithdraw(int settlementId) async {
    try {
      await ref
          .read(settlementRepositoryProvider)
          .requestWithdraw(settlementId, settlementTutorId);
      ref.invalidate(settlementDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출금 요청이 접수되었습니다.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출금 요청에 실패했습니다: $error')),
        );
      }
    }
  }
}
