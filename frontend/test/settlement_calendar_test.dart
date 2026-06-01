import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieum/features/tutor/screens/tutor_settlement_screen.dart';

void main() {
  testWidgets('입출금 달력 바텀시트가 레이아웃 오류 없이 열림', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: TutorSettlementScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('21').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
