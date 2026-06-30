import 'package:flutter_test/flutter_test.dart';
import 'package:tcg/main.dart';
import 'package:tcg/viewmodels/settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App Boot Smoke Test', (WidgetTester tester) async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    
    // Create required SettingsViewModel
    final settingsVM = SettingsViewModel();
    
    // Build our app and trigger a frame.
    // We remove 'const' because settingsVM is a dynamic object
    await tester.pumpWidget(MyApp(settingsVM: settingsVM));
    
    // Verify that MyApp is rendered
    expect(find.byType(MyApp), findsOneWidget);
  });
}
