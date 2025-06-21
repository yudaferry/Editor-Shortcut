import 'dart:io';

class PathService {
  static final PathService _instance = PathService._internal();
  factory PathService() => _instance;
  PathService._internal();

  /// Converts WSL path to Windows path
  /// Example: /mnt/c/Users/username/project -> C:\Users\username\project
  String wslToWindows(String wslPath) {
    if (!wslPath.startsWith('/mnt/')) {
      return wslPath; // Not a WSL mount path
    }

    // Extract the drive letter and path
    final parts = wslPath.split('/');
    if (parts.length < 3 || parts[1] != 'mnt') {
      return wslPath; // Invalid WSL mount path
    }

    final driveLetter = parts[2].toUpperCase();
    final remainingPath = parts.skip(3).join('\\');
    
    return '$driveLetter:\\$remainingPath';
  }

  /// Converts Windows path to WSL path
  /// Example: C:\Users\username\project -> /mnt/c/Users/username/project
  String windowsToWsl(String windowsPath) {
    if (!windowsPath.contains(':')) {
      return windowsPath; // Not a Windows path
    }

    // Handle both forward and backward slashes
    final normalizedPath = windowsPath.replaceAll('\\', '/');
    final parts = normalizedPath.split('/');
    
    if (parts.isEmpty || !parts[0].contains(':')) {
      return windowsPath; // Invalid Windows path
    }

    final driveLetter = parts[0].substring(0, 1).toLowerCase();
    final remainingPath = parts.skip(1).join('/');
    
    return '/mnt/$driveLetter/$remainingPath';
  }

  /// Detects if running in WSL environment
  Future<bool> isWslEnvironment() async {
    try {
      // Check if /proc/version exists and contains WSL
      final procVersionFile = File('/proc/version');
      if (await procVersionFile.exists()) {
        final content = await procVersionFile.readAsString();
        return content.toLowerCase().contains('wsl') || 
               content.toLowerCase().contains('microsoft');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validates if a path exists (works for both Windows and WSL paths)
  Future<bool> pathExists(String path) async {
    try {
      // Try direct path first
      if (await Directory(path).exists() || await File(path).exists()) {
        return true;
      }

      // If in WSL and path looks like Windows path, convert and try
      if (await isWslEnvironment() && path.contains(':')) {
        final wslPath = windowsToWsl(path);
        return await Directory(wslPath).exists() || await File(wslPath).exists();
      }

      // If path looks like WSL mount and we're on Windows, convert and try
      if (Platform.isWindows && path.startsWith('/mnt/')) {
        final windowsPath = wslToWindows(path);
        return await Directory(windowsPath).exists() || await File(windowsPath).exists();
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets the appropriate path for the current environment
  Future<String> getExecutablePath(String path) async {
    // If in WSL and path is Windows format, convert to WSL
    if (await isWslEnvironment() && path.contains(':')) {
      return windowsToWsl(path);
    }
    
    // If on Windows and path is WSL format, convert to Windows
    if (Platform.isWindows && path.startsWith('/mnt/')) {
      return wslToWindows(path);
    }
    
    return path;
  }

  /// Normalizes path separators for display
  String normalizePath(String path) {
    if (Platform.isWindows) {
      return path.replaceAll('/', '\\');
    } else {
      return path.replaceAll('\\', '/');
    }
  }

  /// Gets the display name for a path (shows both formats if applicable)
  String getDisplayPath(String path) {
    if (path.startsWith('/mnt/')) {
      final windowsPath = wslToWindows(path);
      return '$windowsPath (WSL: $path)';
    } else if (path.contains(':')) {
      final wslPath = windowsToWsl(path);
      return '$path (WSL: $wslPath)';
    }
    return path;
  }

  /// Extracts project name from path
  String getProjectNameFromPath(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final parts = normalizedPath.split('/');
    return parts.last.isNotEmpty ? parts.last : parts[parts.length - 2];
  }

  /// Validates if path is a valid project directory
  Future<bool> isValidProjectPath(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        return false;
      }

      // Check if it's a directory (not a file)
      final stat = await directory.stat();
      return stat.type == FileSystemEntityType.directory;
    } catch (e) {
      return false;
    }
  }

  /// Common project indicators (for future enhancement)
  static const List<String> projectIndicators = [
    'package.json',
    'pubspec.yaml',
    'Cargo.toml',
    'pom.xml',
    'build.gradle',
    'requirements.txt',
    'composer.json',
    '.git',
    '.gitignore',
    'README.md',
  ];

  /// Checks if directory contains project indicators
  Future<bool> hasProjectIndicators(String path) async {
    try {
      final directory = Directory(path);
      final contents = await directory.list().toList();
      
      for (final indicator in projectIndicators) {
        final exists = contents.any((entity) => 
          entity.path.endsWith(indicator) || 
          entity.path.endsWith('/$indicator') ||
          entity.path.endsWith('\\$indicator')
        );
        if (exists) return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}