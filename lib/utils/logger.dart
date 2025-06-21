import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart';

class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static bool _initialized = false;

  static Future<void> _initialize() async {
    if (_initialized) return;
    
    try {
      // Get current project directory for logs
      final currentDir = Directory.current;
      final logDir = Directory(join(currentDir.path, 'logs'));
      
      // Create logs directory if it doesn't exist
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      
      // Create log file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      _logFile = File(join(logDir.path, 'app_$timestamp.log'));
      
      // Initialize logger with file output
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: false, // No colors for file output
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
        output: MultiOutput([
          ConsoleOutput(), // Console output
          FileOutput(file: _logFile!), // File output
        ]),
      );
      
      _initialized = true;
      print('📄 Log file created: ${_logFile!.path}');
    } catch (e) {
      print('⚠️ Failed to initialize file logging: $e');
      // Fallback to console-only logging
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );
      _initialized = true;
    }
  }

  static Future<Logger> get logger async {
    await _initialize();
    return _logger!;
  }

  static void debug(String message) async {
    final log = await logger;
    log.d(message);
  }

  static void info(String message) async {
    final log = await logger;
    log.i(message);
  }

  static void warning(String message) async {
    final log = await logger;
    log.w(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) async {
    final log = await logger;
    log.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) async {
    final log = await logger;
    log.f(message, error: error, stackTrace: stackTrace);
  }

  static String? get logFilePath => _logFile?.path;
}

class FileOutput extends LogOutput {
  final File file;
  
  FileOutput({required this.file});
  
  @override
  void output(OutputEvent event) {
    try {
      final logEntry = event.lines.join('\n');
      final timestamp = DateTime.now().toIso8601String();
      file.writeAsStringSync('[$timestamp] $logEntry\n', mode: FileMode.append);
    } catch (e) {
      print('Error writing to log file: $e');
    }
  }
}