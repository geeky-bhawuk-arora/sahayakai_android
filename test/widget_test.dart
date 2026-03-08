import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahayakai_android/main.dart';

void main() {
  testWidgets('App starts at splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SahayakApp()));

    // Verify that the splash screen text is present.
    expect(find.text('SAHAYAK AI'), findsOneWidget);
  });
}
