import 'package:flutter_test/flutter_test.dart';
import 'package:ieum/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('이음 앱 기본 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: IeumApp()),
    );
    expect(find.text('이음'), findsOneWidget);
  });
}