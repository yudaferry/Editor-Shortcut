import 'package:flutter/material.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

void main() async {
  // Suppress GTK/GDK messages on Linux
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.info('🚀 Project Manager App starting...');
  
  // Initialize window manager for desktop
  await windowManager.ensureInitialized();
  
  // Configure window settings - remove title bar
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Hide OS title bar
    windowButtonVisibility: false, // Hide window buttons
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Start in maximized mode (close to full screen)
    await windowManager.maximize();
  });
  
  // Initialize SQLite for desktop
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  
  runApp(const ProjectManagerApp());
}

class ProjectManagerApp extends StatelessWidget {
  const ProjectManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Follow system theme
      home: const HomeScreen(),
    );
  }
}

