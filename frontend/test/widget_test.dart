import 'package:flutter_test/flutter_test.dart';
import 'package:ieum/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('온샘 앱 기본 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OnsaemApp()),
    );
    expect(find.text('온샘'), findsOneWidget);
  });
}
