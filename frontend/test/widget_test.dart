import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/health_provider.dart';
import 'package:ieum/main.dart';

void main() {
  testWidgets('온샘 앱 기본 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith((ref) async => 'ok'),
        ],
        child: const OnsaemApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('온샘'), findsOneWidget);
  });
}
