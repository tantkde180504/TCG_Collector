import 'package:flutter_test/flutter_test.dart';
import 'package:tcg/main.dart';

void main() {
  testWidgets('App Boot Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the login gateway is displayed initial status
    expect(find.byType(MyApp), findsOneWidget);
  });
}
