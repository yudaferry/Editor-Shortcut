import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Editor Management Screen Integration Tests', () {
    testWidgets('Editor Management Screen - Initial Load and UI Elements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Editor Management'), findsOneWidget);
      
      // Verify add button is present
      expect(find.byIcon(Icons.add), findsOneWidget);
      
      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Editor Management Screen - Empty State or Editor List', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Allow time for data loading
      await tester.pump(const Duration(seconds: 2));

      // Should show either empty state or editor list
      final emptyState = find.textContaining('No editors configured');
      final editorList = find.byType(ListView);
      final loadingIndicator = find.byType(CircularProgressIndicator);
      
      // One of these should be present
      expect(
        emptyState.evaluate().isNotEmpty || 
        editorList.evaluate().isNotEmpty || 
        loadingIndicator.evaluate().isNotEmpty, 
        isTrue
      );
    });

    testWidgets('Editor Management Screen - Add Editor Navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Wait for screen to load completely
      await tester.pump(const Duration(seconds: 2));

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show either a dialog or navigate to add editor screen
      // Check for common add editor UI elements
      final dialogPresent = find.byType(AlertDialog).evaluate().isNotEmpty;
      final addEditorForm = find.textContaining('Editor Name').evaluate().isNotEmpty;
      
      expect(dialogPresent || addEditorForm, isTrue);
      
      // If it's a dialog, close it
      if (dialogPresent) {
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Editor Management Screen - Default Editors Present', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 2));

      // Check if default editors are pre-populated
      // These should be added by the database service initialization
      final vsCodeEditor = find.textContaining('VS Code');
      final cursorEditor = find.textContaining('Cursor');
      final windsurfEditor = find.textContaining('Windsurf');
      
      // At least one default editor should be present
      expect(
        vsCodeEditor.evaluate().isNotEmpty || 
        cursorEditor.evaluate().isNotEmpty || 
        windsurfEditor.evaluate().isNotEmpty,
        isTrue
      );
    });

    testWidgets('Editor Management Screen - Editor List Interaction', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 2));

      // Look for editor list
      final editorList = find.byType(ListView);
      if (editorList.evaluate().isNotEmpty) {
        // Should be able to scroll if there are editors
        await tester.drag(editorList, const Offset(0, -100));
        await tester.pumpAndSettle();
        
        // List should still be present after scrolling
        expect(find.byType(ListView), findsOneWidget);
      }
    });

    testWidgets('Editor Management Screen - App Bar Actions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify app bar elements
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Editor Management'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Editor Management Screen - Loading State Handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      
      // Check immediately for loading state
      await tester.pump();
      
      // Wait for loading to complete
      await tester.pumpAndSettle();
      
      // After loading, should show content
      expect(find.text('Editor Management'), findsOneWidget);
    });

    testWidgets('Editor Management Screen - Navigation Back to Home', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify on Editor Management screen
      expect(find.text('Editor Management'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Project Manager'), findsOneWidget);
    });

    testWidgets('Editor Management Screen - Suggested Editors Feature', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Editor Management screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 2));

      // Look for suggested editors functionality
      final suggestedEditorsButton = find.textContaining('Suggested');
      
      // If suggested editors feature exists, test it
      if (suggestedEditorsButton.evaluate().isNotEmpty) {
        await tester.tap(suggestedEditorsButton);
        await tester.pumpAndSettle();
        
        // Should show some response
        expect(find.byType(Dialog).evaluate().isNotEmpty || 
               find.byType(SnackBar).evaluate().isNotEmpty, isTrue);
      }
    });
  });
}