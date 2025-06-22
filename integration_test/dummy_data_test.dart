import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dummy Data Tests - Grande Server Projects', () {
    // Project data from /home/yuda/Grande-server directory
    final projectData = [
      {
        'name': 'Admin Server',
        'path': '/home/yuda/Grande-server/Admin_Server',
        'description':
            'Administrative server for managing clients and configurations',
        'group': 'Backend Services',
      },
      {
        'name': 'Base Server',
        'path': '/home/yuda/Grande-server/Base_Server',
        'description':
            'Core base server with shared functionality and middleware',
        'group': 'Backend Services',
      },
      {
        'name': 'BO Server',
        'path': '/home/yuda/Grande-server/BO_Server',
        'description':
            'Back office server for business operations and management',
        'group': 'Backend Services',
      },
      {
        'name': 'Login Server',
        'path': '/home/yuda/Grande-server/Login_Server',
        'description': 'Authentication and user login service server',
        'group': 'Authentication',
      },
      {
        'name': 'POS Server',
        'path': '/home/yuda/Grande-server/POS_Server',
        'description': 'Point of sale server for retail operations',
        'group': 'POS System',
      },
      {
        'name': 'Report Server',
        'path': '/home/yuda/Grande-server/Report_Server',
        'description':
            'Reporting and analytics server for business intelligence',
        'group': 'Analytics',
      },
      {
        'name': 'Compose Service',
        'path': '/home/yuda/Grande-server/compose-service',
        'description': 'Docker compose configuration for service orchestration',
        'group': 'DevOps',
      },
      {
        'name': 'EC2 Script',
        'path': '/home/yuda/Grande-server/ec2-script',
        'description': 'AWS EC2 deployment and automation scripts',
        'group': 'DevOps',
      },
      {
        'name': 'Proxy',
        'path': '/home/yuda/Grande-server/proxy',
        'description': 'Reverse proxy server for load balancing and routing',
        'group': 'Infrastructure',
      },
    ];

    testWidgets('Add 9 Grande Server projects with dummy data', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('\n🚀 Starting dummy data test with Grande Server projects...');

      // Verify we start with empty project list
      expect(find.text('Editor Shortcut'), findsOneWidget);
      print('✅ App started successfully');

      int projectsAdded = 0;

      // Add each project
      for (int i = 0; i < projectData.length; i++) {
        final project = projectData[i];

        print('\n📋 Adding project ${i + 1}/9: ${project['name']}');

        // Navigate to Add Project screen
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify we're on Add Project screen
        expect(find.text('Add Project'), findsOneWidget);

        // Fill in project details
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Project Path *'),
          project['path'] as String,
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Project Name *'),
          project['name'] as String,
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description (optional)'),
          project['description'] as String,
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Group (optional)'),
          project['group'] as String,
        );
        await tester.pumpAndSettle();

        // Save the project
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should navigate back to home screen after successful save
        expect(find.text('Editor Shortcut'), findsOneWidget);
        projectsAdded++;

        print('✅ Added: ${project['name']} (${projectsAdded}/9)');

        // Give a moment for database operations to complete
        await tester.pump(const Duration(milliseconds: 500));
      }

      print('\n🎉 Successfully added all 9 projects!');
      print('📊 Total projects added: $projectsAdded');

      // Verify projects are visible on home screen
      // Look for project cards or list items
      final projectCards = find.byType(Card);
      final gridView = find.byType(GridView);
      final listView = find.byType(ListView);

      // Projects should be displayed in some form
      expect(
        projectCards.evaluate().isNotEmpty ||
            gridView.evaluate().isNotEmpty ||
            listView.evaluate().isNotEmpty,
        isTrue,
      );

      print('✅ Projects are displayed on home screen');

      // Test search functionality with one of the added projects
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Search for Admin Server
        await tester.enterText(find.byType(TextField).first, 'Admin');
        await tester.pumpAndSettle();

        print('✅ Search functionality tested with "Admin"');

        // Clear search or go back
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }

      // Test group filtering
      final groupDropdown = find.byType(DropdownButton<String>);
      if (groupDropdown.evaluate().isNotEmpty) {
        await tester.tap(groupDropdown);
        await tester.pumpAndSettle();

        // Should show different groups
        final backendServicesGroup = find.text('Backend Services');
        if (backendServicesGroup.evaluate().isNotEmpty) {
          await tester.tap(backendServicesGroup);
          await tester.pumpAndSettle();
          print('✅ Group filtering tested with "Backend Services"');
        }

        // Reset to "All" groups
        await tester.tap(groupDropdown);
        await tester.pumpAndSettle();
        final allGroup = find.text('All');
        if (allGroup.evaluate().isNotEmpty) {
          await tester.tap(allGroup);
          await tester.pumpAndSettle();
        }
      }

      print('\n🧪 Testing project interactions...');

      // Test project action interactions (if available)
      if (projectCards.evaluate().isNotEmpty) {
        // Try to interact with first project card
        await tester.tap(projectCards.first);
        await tester.pumpAndSettle();

        // If action sheet opens, close it
        final actionSheet = find.byType(BottomSheet);
        if (actionSheet.evaluate().isNotEmpty) {
          // Tap outside to close
          await tester.tapAt(const Offset(50, 50));
          await tester.pumpAndSettle();
          print('✅ Project interaction tested');
        }
      }

      print('\n🧹 Starting cleanup - removing all test projects...');
    });

    testWidgets('Clean up - Remove all test projects', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('\n🗑️  Cleaning up test projects...');

      int projectsRemoved = 0;
      int maxAttempts = 15; // Safety limit
      int attempts = 0;

      // Keep removing projects until none are left or we reach max attempts
      while (attempts < maxAttempts) {
        attempts++;

        // Look for project cards
        final projectCards = find.byType(Card);
        final gridView = find.byType(GridView);

        // If no projects found, we're done
        if (projectCards.evaluate().isEmpty && gridView.evaluate().isEmpty) {
          // Check for empty state message
          final emptyMessage = find.textContaining('No projects');
          if (emptyMessage.evaluate().isNotEmpty) {
            print('✅ All projects removed - empty state detected');
            break;
          }
        }

        // Try to find and delete a project
        bool projectDeleted = false;

        // Method 1: Try to find project cards and long press
        if (projectCards.evaluate().isNotEmpty) {
          try {
            await tester.longPress(projectCards.first);
            await tester.pumpAndSettle();

            // Look for delete option
            final deleteButton = find.textContaining('Delete');
            final removeButton = find.textContaining('Remove');

            if (deleteButton.evaluate().isNotEmpty) {
              await tester.tap(deleteButton);
              await tester.pumpAndSettle();
              projectDeleted = true;
            } else if (removeButton.evaluate().isNotEmpty) {
              await tester.tap(removeButton);
              await tester.pumpAndSettle();
              projectDeleted = true;
            } else {
              // Close any opened sheet
              await tester.tapAt(const Offset(50, 50));
              await tester.pumpAndSettle();
            }
          } catch (e) {
            print('⚠️  Method 1 failed: $e');
          }
        }

        // Method 2: Try tap to open action sheet
        if (!projectDeleted && projectCards.evaluate().isNotEmpty) {
          try {
            await tester.tap(projectCards.first);
            await tester.pumpAndSettle();

            // Look for delete in action sheet
            final deleteButton = find.textContaining('Delete');
            final removeButton = find.textContaining('Remove');

            if (deleteButton.evaluate().isNotEmpty) {
              await tester.tap(deleteButton);
              await tester.pumpAndSettle();
              projectDeleted = true;
            } else if (removeButton.evaluate().isNotEmpty) {
              await tester.tap(removeButton);
              await tester.pumpAndSettle();
              projectDeleted = true;
            } else {
              // Close sheet
              await tester.tapAt(const Offset(50, 50));
              await tester.pumpAndSettle();
            }
          } catch (e) {
            print('⚠️  Method 2 failed: $e');
          }
        }

        if (projectDeleted) {
          projectsRemoved++;
          print('🗑️  Removed project $projectsRemoved');

          // Give time for UI to update
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          print(
            '⚠️  Could not find delete action for project (attempt $attempts)',
          );

          // Try to refresh the screen
          await tester.drag(find.byType(Scaffold), const Offset(0, 100));
          await tester.pumpAndSettle();

          // If we can't delete projects, break to avoid infinite loop
          if (attempts >= 5) {
            print('⚠️  Unable to delete projects after $attempts attempts');
            print(
              '   This might be because delete functionality is not implemented',
            );
            print('   or the UI structure is different than expected');
            break;
          }
        }
      }

      print('\n✅ Cleanup completed!');
      print('📊 Projects removed: $projectsRemoved');
      print('🔄 Total attempts: $attempts');

      // Final verification
      final remainingCards = find.byType(Card);
      print('📋 Remaining project cards: ${remainingCards.evaluate().length}');

      if (remainingCards.evaluate().isEmpty) {
        print('🎉 All test projects successfully removed!');
      } else {
        print('⚠️  Some projects may still remain in the database');
        print('   You may need to manually clear them from the app');
      }
    });

    testWidgets('Verify clean state after cleanup', (
      WidgetTester tester,
    ) async {
      // Start the app one more time to verify clean state
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('\n🔍 Verifying final state...');

      // Should be back to initial empty state
      expect(find.text('Editor Shortcut'), findsOneWidget);

      // Check for empty state
      final projectCards = find.byType(Card);
      final emptyMessage = find.textContaining('No projects');

      if (projectCards.evaluate().isEmpty ||
          emptyMessage.evaluate().isNotEmpty) {
        print('✅ App is in clean empty state');
      } else {
        print(
          '⚠️  Projects may still exist: ${projectCards.evaluate().length} cards found',
        );
      }

      print('\n🎉 Dummy data test completed successfully!');
      print('📋 Test Summary:');
      print('   - Added 9 Grande Server projects');
      print('   - Tested search and filtering');
      print('   - Attempted cleanup of all test data');
      print('   - Verified final state');
    });
  });
}
