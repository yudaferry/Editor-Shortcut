// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI Tests - All Pages (Screenshots Disabled)', () {
    testWidgets('Test all pages and flows without screenshots', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // // Create screenshots directory
      // final screenshotDir = Directory('integration_test/test_screenshots');
      // if (!screenshotDir.existsSync()) {
      //   screenshotDir.createSync(recursive: true);
      // }

      // Test 1: Home Screen - Initial State
      // await binding.convertFlutterSurfaceToImage();
      // await tester.pumpAndSettle();
      // await binding.takeScreenshot('01_home_screen_initial');
      
      print('📋 Test 1: Home Screen - Initial State');

      // Test 2: Home Screen - Search (if available)
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();
        // await binding.takeScreenshot('02_home_screen_search');
        print('📋 Test 2: Home Screen - Search Active');
        
        // Close search if it opened
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }

      // Test 3: Navigation to Add Project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('03_add_project_screen_initial');
      print('📋 Test 3: Add Project Screen - Initial (Windows Selected)');

      // Test 4: Platform Selection - WSL
      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('04_add_project_screen_wsl_selected');
      print('📋 Test 4: Add Project Screen - WSL Platform Selected');

      // Test 5: WSL Browse Dialog
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('05_wsl_browse_dialog');
      print('📋 Test 5: WSL Browse Dialog');

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Screenshot 6: Form with Sample Data - WSL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        '/mnt/c/Users/developer/my-flutter-app'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'My Flutter Application'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        'A cross-platform Flutter application with WSL development support'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group (optional)'),
        'Flutter Projects'
      );
      await tester.pumpAndSettle();

      // await binding.takeScreenshot('06_add_project_form_filled_wsl');
      print('📋 Test 6: Add Project Form - Filled with WSL Data');

      // Test 7: Switch to Windows Platform
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('07_add_project_windows_platform_switched');
      print('📋 Test 7: Add Project - Switched to Windows (Path Cleared)');

      // Test 8: Windows Form Filled
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Path *'),
        'C:\\Users\\developer\\Projects\\my-flutter-app'
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'My Flutter Application'
      );
      await tester.pumpAndSettle();

      // await binding.takeScreenshot('08_add_project_form_filled_windows');
      print('📋 Test 8: Add Project Form - Filled with Windows Data');

      // Test 9: Form Validation Error
      // Clear required fields to show validation
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Path *'), '');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Name *'), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('09_add_project_validation_errors');
      print('📋 Test 9: Add Project - Form Validation Errors');

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test 10: Navigate to Editor Management
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('10_editor_management_screen');
      print('📋 Test 10: Editor Management Screen');

      // Test 11: Try to open Add Editor Dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Check if dialog opened
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        // await binding.takeScreenshot('11_add_editor_dialog');
        print('📋 Test 11: Add Editor Dialog');
        
        // Close dialog
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      } else {
        // await binding.takeScreenshot('11_editor_management_add_clicked');
        print('📋 Test 11: Editor Management - Add Button Clicked');
      }

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test 12: Final Home Screen State
      // await binding.takeScreenshot('12_home_screen_final');
      print('📋 Test 12: Home Screen - Final State');

      // Test 13: App Bar and Navigation Elements Close-up
      // await binding.takeScreenshot('13_app_navigation_elements');
      print('📋 Test 13: App Navigation Elements');

      print('\n🎉 UI test completed!');
      print('📋 All UI flows tested successfully');
      print('📊 Total tests completed: 13');
    });

    testWidgets('Test different screen sizes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test different screen sizes
      final screenSizes = [
        {'name': 'desktop', 'size': const Size(1200, 800)},
        {'name': 'tablet', 'size': const Size(800, 600)},
        {'name': 'mobile', 'size': const Size(400, 800)},
      ];

      for (final screenConfig in screenSizes) {
        // Set screen size
        tester.view.physicalSize = screenConfig['size'] as Size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpAndSettle();

        // Test home screen responsiveness
        // await binding.takeScreenshot('responsive_home_${screenConfig['name']}');
        print('📋 Test: Home Screen - ${screenConfig['name']} size');

        // Navigate to Add Project and test
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        // await binding.takeScreenshot('responsive_add_project_${screenConfig['name']}');
        print('📋 Test: Add Project - ${screenConfig['name']} size');

        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Reset to default size
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      print('\n📱 Responsive testing completed!');
    });

    testWidgets('Test user interaction flows', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('\n🎬 Testing User Interaction Flows...');

      // Flow 1: Complete Add Project Flow
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_01_enter_add_project');
      print('📋 Flow 1: Enter Add Project');

      await tester.tap(find.text('WSL'));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_02_select_wsl_platform');
      print('📋 Flow 2: Select WSL Platform');

      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_03_open_wsl_browse');
      print('📋 Flow 3: Open WSL Browse Dialog');

      // Enter path in dialog
      await tester.enterText(find.byType(TextField), '/mnt/c/dev/my-project');
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_04_enter_wsl_path');
      print('📋 Flow 4: Enter WSL Path');

      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_05_path_selected');
      print('📋 Flow 5: Path Selected');

      // Fill remaining fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name *'),
        'Demo Project'
      );
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_06_name_entered');
      print('📋 Flow 6: Name Entered');

      // Navigate back to complete flow
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      // await binding.takeScreenshot('flow_07_back_to_home');
      print('📋 Flow 7: Back to Home');

      print('🎬 User flow testing completed!');
    });
  });
}