import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Add Project Screen Integration Tests', () {
    testWidgets('Add Project Screen - Initial UI and Platform Selection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Add Project'), findsOneWidget);
      
      // Verify platform selection card
      expect(find.text('Select Platform'), findsOneWidget);
      expect(find.text('Windows'), findsOneWidget);
      expect(find.text('WSL'), findsOneWidget);
      
      // Verify Windows is selected by default
      final windowsRadio = find.byWidgetPredicate((widget) =>
        widget is Radio<String> && 
        widget.value == 'windows' && 
        widget.groupValue == 'windows'
      );
      expect(windowsRadio, findsOneWidget);
    });

    testWidgets('Add Project Screen - Platform Switching', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Initially Windows should be selected
      expect(find.byWidgetPredicate((widget) =>
        widget is Radio<String> && 
        widget.value == 'windows' && 
        widget.groupValue == 'windows'
      ), findsOneWidget);

      // Switch to WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      // Verify WSL is now selected
      expect(find.byWidgetPredicate((widget) =>
        widget is Radio<String> && 
        widget.value == 'wsl' && 
        widget.groupValue == 'wsl'
      ), findsOneWidget);

      // Switch back to Windows
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();

      // Verify Windows is selected again
      expect(find.byWidgetPredicate((widget) =>
        widget is Radio<String> && 
        widget.value == 'windows' && 
        widget.groupValue == 'windows'
      ), findsOneWidget);
    });

    testWidgets('Add Project Screen - Form Fields Present', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify all form fields are present
      expect(find.text('Project Path *'), findsOneWidget);
      expect(find.text('Project Name *'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.text('Group (optional)'), findsOneWidget);
      
      // Verify browse button
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      
      // Verify save button
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Add Project Screen - Form Validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('Project path is required'), findsOneWidget);
      expect(find.text('Project name is required'), findsOneWidget);
    });

    testWidgets('Add Project Screen - Path Input for Windows Platform', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Ensure Windows is selected
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();

      // Enter a Windows-style path
      final pathField = find.widgetWithText(TextFormField, 'Project Path *');
      await tester.enterText(pathField, 'C:\\Users\\test\\project');
      await tester.pumpAndSettle();

      // Verify path was entered
      expect(find.text('C:\\Users\\test\\project'), findsOneWidget);
      
      // Path should be entered successfully
      expect(find.text('C:\\Users\\test\\project'), findsOneWidget);
    });

    testWidgets('Add Project Screen - Path Input for WSL Platform', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Switch to WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      // Enter a WSL-style path
      final pathField = find.widgetWithText(TextFormField, 'Project Path *');
      await tester.enterText(pathField, '/mnt/c/Users/test/project');
      await tester.pumpAndSettle();

      // Verify path was entered
      expect(find.text('/mnt/c/Users/test/project'), findsOneWidget);
      
      // Path should be entered successfully
      expect(find.text('/mnt/c/Users/test/project'), findsOneWidget);
    });

    testWidgets('Add Project Screen - WSL Browse Dialog', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Switch to WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      // Tap browse button
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();

      // Verify WSL dialog opened
      expect(find.text('WSL Directory Path'), findsOneWidget);
      expect(find.text('Common WSL Paths:'), findsOneWidget);
      expect(find.text('Examples:'), findsOneWidget);
      
      // Verify common path chips
      expect(find.text('/mnt/c/Users/'), findsOneWidget);
      expect(find.text('/home/'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Verify back to Add Project screen
      expect(find.text('Add Project'), findsOneWidget);
    });

    testWidgets('Add Project Screen - Complete Form Filling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill all form fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        'C:\\test\\project'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'Test Project'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        'A test project for integration testing'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group (optional)'),
        'Test Group'
      );
      await tester.pumpAndSettle();

      // Verify all fields have values
      expect(find.text('C:\\test\\project'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('A test project for integration testing'), findsOneWidget);
      expect(find.text('Test Group'), findsOneWidget);
    });

    testWidgets('Add Project Screen - Platform Switch Clears Path', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter Windows path
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        'C:\\test\\project'
      );
      await tester.pumpAndSettle();

      // Verify path was entered
      expect(find.text('C:\\test\\project'), findsOneWidget);

      // Switch to WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      // Verify path field is cleared
      final pathField = find.widgetWithText(TextFormField, 'Project Path *');
      final textField = tester.widget<TextFormField>(pathField);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Add Project Screen - Navigation Back to Home', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify on Add Project screen
      expect(find.text('Add Project'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Project Manager'), findsOneWidget);
    });
  });
}