import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow Integration Tests', () {
    testWidgets('Complete Navigation Flow - Home → Add Project → Home', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start from home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);

      // Navigate to Add Project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify on Add Project screen
      expect(find.text('Add Project'), findsOneWidget);
      expect(find.text('Select Platform'), findsOneWidget);

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Complete Navigation Flow - Home → Editor Management → Home', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start from home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);

      // Navigate to Editor Management
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify on Editor Management screen
      expect(find.text('Editor Management'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);
    });

    testWidgets(
      'Complex Navigation Flow - Home → Add Project → Home → Editor Management → Home',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Start from home
        expect(find.text('Editor Shortcut'), findsOneWidget);

        // Go to Add Project
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('Add Project'), findsOneWidget);

        // Back to home
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Editor Shortcut'), findsOneWidget);

        // Go to Editor Management
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        expect(find.text('Editor Management'), findsOneWidget);

        // Back to home
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Editor Shortcut'), findsOneWidget);
      },
    );

    testWidgets('Platform Selection Flow in Add Project', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Test Windows platform selection (default)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Radio<String> &&
              widget.value == 'windows' &&
              widget.groupValue == 'windows',
        ),
        findsOneWidget,
      );

      // Switch to WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Radio<String> &&
              widget.value == 'wsl' &&
              widget.groupValue == 'wsl',
        ),
        findsOneWidget,
      );

      // Test WSL browse dialog flow
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();

      expect(find.text('WSL Directory Path'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Project'), findsOneWidget);

      // Switch back to Windows
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Radio<String> &&
              widget.value == 'windows' &&
              widget.groupValue == 'windows',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Form Validation Flow in Add Project', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to save empty form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text('Project path is required'), findsOneWidget);
      expect(find.text('Project name is required'), findsOneWidget);

      // Fill only path
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        'C:\\test\\path',
      );
      await tester.pumpAndSettle();

      // Try to save with only path
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should still show name validation
      expect(find.text('Project name is required'), findsOneWidget);

      // Path validation should be cleared
      expect(find.text('Project path is required'), findsNothing);

      // Fill name field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'Test Project',
      );
      await tester.pumpAndSettle();

      // Both required fields now have values
      expect(find.text('C:\\test\\path'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('App State Persistence During Navigation', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project and fill some data
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'Persistent Test',
      );
      await tester.pumpAndSettle();

      // Switch platforms to test state clearing
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();

      // Name should persist, but path should clear
      expect(find.text('Persistent Test'), findsOneWidget);

      // Add WSL path
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        '/mnt/c/test/path',
      );
      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Form should be reset for new project
      final pathField = find.widgetWithText(TextFormField, 'Project Path *');
      final nameField = find.widgetWithText(TextFormField, 'Project Name *');

      expect(pathField, findsOneWidget);
      expect(nameField, findsOneWidget);
    });

    testWidgets('Deep Navigation Flow - Multiple Screen Transitions', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Perform multiple rapid navigations
      for (int i = 0; i < 3; i++) {
        // Home → Add Project → Home
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('Add Project'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Editor Shortcut'), findsOneWidget);

        // Home → Editor Management → Home
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        expect(find.text('Editor Management'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Editor Shortcut'), findsOneWidget);
      }

      // App should still be functional after multiple navigations
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Error Handling in Navigation Flow', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Add Project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to trigger browse dialog and cancel multiple times
      for (int i = 0; i < 3; i++) {
        // Switch to WSL and open dialog
        await tester.tap(find.text('WSL'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.folder_open));
        await tester.pumpAndSettle();

        if (find.text('WSL Directory Path').evaluate().isNotEmpty) {
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }

        // Switch back to Windows
        await tester.tap(find.text('Windows'));
        await tester.pumpAndSettle();
      }

      // App should still be functional
      expect(find.text('Add Project'), findsOneWidget);
      expect(find.text('Select Platform'), findsOneWidget);
    });
  });
}
