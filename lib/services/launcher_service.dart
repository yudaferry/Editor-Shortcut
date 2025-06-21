import 'dart:io';
import '../models/editor.dart';
import '../models/project.dart';
import 'path_service.dart';

class LauncherService {
  static final LauncherService _instance = LauncherService._internal();
  factory LauncherService() => _instance;
  LauncherService._internal();

  final PathService _pathService = PathService();

  /// Launches a project with the specified editor
  Future<bool> launchProject(Project project, Editor editor) async {
    try {
      final projectPath = await _pathService.getExecutablePath(project.path);
      
      // Validate that the project path exists
      if (!await _pathService.pathExists(projectPath)) {
        throw Exception('Project path does not exist: ${project.path}');
      }

      // Build the command arguments
      final List<String> arguments = [];
      
      // Add custom arguments if specified
      if (editor.arguments != null && editor.arguments!.isNotEmpty) {
        arguments.addAll(editor.arguments!.split(' '));
      }
      
      // Add the project path
      arguments.add(projectPath);

      // Launch the process
      final result = await Process.run(
        editor.command,
        arguments,
        runInShell: true,
      );

      // Check if the command was successful
      if (result.exitCode == 0) {
        return true;
      } else {
        print('Editor launch failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('Error launching project: $e');
      return false;
    }
  }

  /// Launches a project with the specified editor (non-blocking)
  Future<bool> launchProjectAsync(Project project, Editor editor) async {
    try {
      final projectPath = await _pathService.getExecutablePath(project.path);
      
      // Validate that the project path exists
      if (!await _pathService.pathExists(projectPath)) {
        throw Exception('Project path does not exist: ${project.path}');
      }

      // Build the command arguments
      final List<String> arguments = [];
      
      // Add custom arguments if specified
      if (editor.arguments != null && editor.arguments!.isNotEmpty) {
        arguments.addAll(editor.arguments!.split(' '));
      }
      
      // Add the project path
      arguments.add(projectPath);

      // Start the process without waiting for completion
      await Process.start(
        editor.command,
        arguments,
        runInShell: true,
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('Error launching project: $e');
      return false;
    }
  }

  /// Tests if an editor command is available
  Future<bool> testEditorCommand(String command) async {
    try {
      // Try to run the command with --version or --help
      final result = await Process.run(
        command,
        ['--version'],
        runInShell: true,
      ).timeout(Duration(seconds: 5));

      return result.exitCode == 0;
    } catch (e) {
      try {
        // Try with --help if --version fails
        final result = await Process.run(
          command,
          ['--help'],
          runInShell: true,
        ).timeout(Duration(seconds: 5));

        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }

  /// Gets suggested editors based on the current platform
  List<Editor> getSuggestedEditors() {
    final now = DateTime.now();
    final editors = <Editor>[];

    // Common editors with their typical commands
    final editorConfigs = [
      {'name': 'VS Code', 'command': 'code', 'description': 'Visual Studio Code'},
      {'name': 'Cursor', 'command': 'cursor', 'description': 'Cursor AI Editor'},
      {'name': 'Windsurf', 'command': 'windsurf', 'description': 'Windsurf Editor'},
      {'name': 'IntelliJ IDEA', 'command': 'idea', 'description': 'IntelliJ IDEA'},
      {'name': 'Sublime Text', 'command': 'subl', 'description': 'Sublime Text'},
      {'name': 'Atom', 'command': 'atom', 'description': 'Atom Editor'},
      {'name': 'Vim', 'command': 'vim', 'description': 'Vim Text Editor'},
      {'name': 'Emacs', 'command': 'emacs', 'description': 'Emacs Editor'},
      {'name': 'Nano', 'command': 'nano', 'description': 'Nano Text Editor'},
    ];

    // Add Windows-specific editors
    if (Platform.isWindows) {
      editorConfigs.addAll([
        {'name': 'Notepad++', 'command': 'notepad++', 'description': 'Notepad++'},
        {'name': 'Visual Studio', 'command': 'devenv', 'description': 'Visual Studio'},
      ]);
    }

    for (final config in editorConfigs) {
      editors.add(Editor(
        name: config['name']!,
        command: config['command']!,
        description: config['description'],
        createdAt: now,
        updatedAt: now,
      ));
    }

    return editors;
  }

  /// Opens a file explorer/finder at the project path
  Future<bool> openInFileExplorer(Project project) async {
    try {
      final projectPath = await _pathService.getExecutablePath(project.path);
      
      if (!await _pathService.pathExists(projectPath)) {
        return false;
      }

      String command;
      List<String> arguments;

      if (Platform.isWindows) {
        command = 'explorer';
        arguments = [projectPath];
      } else if (Platform.isMacOS) {
        command = 'open';
        arguments = [projectPath];
      } else {
        // Linux
        command = 'xdg-open';
        arguments = [projectPath];
      }

      await Process.start(
        command,
        arguments,
        runInShell: true,
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('Error opening file explorer: $e');
      return false;
    }
  }

  /// Opens a terminal at the project path
  Future<bool> openInTerminal(Project project) async {
    try {
      final projectPath = await _pathService.getExecutablePath(project.path);
      
      if (!await _pathService.pathExists(projectPath)) {
        return false;
      }

      String command;
      List<String> arguments;

      if (Platform.isWindows) {
        // Try Windows Terminal first, then fallback to cmd
        command = 'wt';
        arguments = ['-d', projectPath];
        
        try {
          await Process.start(command, arguments, runInShell: true, mode: ProcessStartMode.detached);
          return true;
        } catch (e) {
          // Fallback to cmd
          command = 'cmd';
          arguments = ['/c', 'start', 'cmd', '/k', 'cd', '/d', projectPath];
        }
      } else if (Platform.isMacOS) {
        command = 'open';
        arguments = ['-a', 'Terminal', projectPath];
      } else {
        // Linux - try common terminal emulators
        final terminals = ['gnome-terminal', 'xterm', 'konsole', 'xfce4-terminal'];
        
        for (final terminal in terminals) {
          try {
            await Process.start(
              terminal,
              ['--working-directory=$projectPath'],
              runInShell: true,
              mode: ProcessStartMode.detached,
            );
            return true;
          } catch (e) {
            continue;
          }
        }
        return false;
      }

      await Process.start(
        command,
        arguments,
        runInShell: true,
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('Error opening terminal: $e');
      return false;
    }
  }
}