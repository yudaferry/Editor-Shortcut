import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Screen Integration Tests', () {
    testWidgets('Home Screen - Initial Load and UI Elements', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify main UI elements are present
      expect(find.text('Editor Shortcut'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Check for search functionality
      expect(find.byIcon(Icons.search), findsAny);

      // Verify empty state or project list
      final emptyState = find.textContaining('No projects found');
      final projectList = find.byType(GridView);

      // Should show either empty state or project grid
      expect(
        emptyState.evaluate().isNotEmpty || projectList.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Home Screen - Navigation to Add Project', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify navigation to Add Project screen
      expect(find.text('Add Project'), findsOneWidget);
      expect(find.text('Select Platform'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);
    });

    testWidgets('Home Screen - Navigation to Editor Management', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify navigation to Editor Management screen
      expect(find.text('Editor Management'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Editor Shortcut'), findsOneWidget);
    });

    testWidgets('Home Screen - Search Functionality', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for search functionality
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Should show search input
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Test search input
        await tester.enterText(find.byType(TextField).first, 'test search');
        await tester.pumpAndSettle();

        // Verify search text was entered
        expect(find.text('test search'), findsOneWidget);
      }
    });

    testWidgets('Home Screen - Group Filter Functionality', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for group dropdown
      final groupDropdown = find.byType(DropdownButton<String>);
      if (groupDropdown.evaluate().isNotEmpty) {
        await tester.tap(groupDropdown);
        await tester.pumpAndSettle();

        // Should show dropdown options
        expect(find.text('All'), findsAtLeastNWidgets(1));

        // Tap outside to close dropdown
        await tester.tapAt(const Offset(50, 50));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Home Screen - App Bar Actions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);

      // Check for app bar title
      expect(find.text('Editor Shortcut'), findsOneWidget);

      // Verify action buttons in app bar
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
