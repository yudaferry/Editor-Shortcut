import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/project.dart';
import '../models/editor.dart';
import '../models/project_group.dart';
import '../utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    if (!_initialized) {
      await _initializeSqlite();
      _initialized = true;
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _initializeSqlite() async {
    AppLogger.info('🔧 Initializing SQLite for desktop...');
    
    // Initialize SQLite for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      AppLogger.info('✅ SQLite FFI initialized for desktop');
    } else {
      AppLogger.info('📱 Using standard SQLite for mobile');
    }
  }

  Future<Database> _initDatabase() async {
    try {
      AppLogger.info('📁 Initializing database...');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'project_manager.db');
      
      AppLogger.info('💾 Database path: $path');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Database initialization failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('🔨 Creating database tables...');
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        group_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE editors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        command TEXT NOT NULL,
        arguments TEXT,
        description TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE project_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        color TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default editors
    final now = DateTime.now().toIso8601String();
    await db.insert('editors', {
      'name': 'VS Code',
      'command': 'code',
      'arguments': null,
      'description': 'Visual Studio Code',
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('editors', {
      'name': 'Cursor',
      'command': 'cursor',
      'arguments': null,
      'description': 'Cursor AI Editor',
      'is_default': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('editors', {
      'name': 'Windsurf',
      'command': 'windsurf',
      'arguments': null,
      'description': 'Windsurf Editor',
      'is_default': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Project CRUD operations
  Future<int> insertProject(Project project) async {
    final db = await database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> getProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('projects');
    return List.generate(maps.length, (i) => Project.fromMap(maps[i]));
  }

  Future<List<Project>> getProjectsByGroup(String? group) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: group != null ? 'group_name = ?' : 'group_name IS NULL',
      whereArgs: group != null ? [group] : null,
    );
    return List.generate(maps.length, (i) => Project.fromMap(maps[i]));
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Editor CRUD operations
  Future<int> insertEditor(Editor editor) async {
    final db = await database;
    return await db.insert('editors', editor.toMap());
  }

  Future<List<Editor>> getEditors() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('editors');
    return List.generate(maps.length, (i) => Editor.fromMap(maps[i]));
  }

  Future<Editor?> getDefaultEditor() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'editors',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps.isNotEmpty ? Editor.fromMap(maps.first) : null;
  }

  Future<int> updateEditor(Editor editor) async {
    final db = await database;
    return await db.update(
      'editors',
      editor.toMap(),
      where: 'id = ?',
      whereArgs: [editor.id],
    );
  }

  Future<int> deleteEditor(int id) async {
    final db = await database;
    return await db.delete(
      'editors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultEditor(int editorId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Remove default from all editors
      await txn.update(
        'editors',
        {'is_default': 0},
        where: 'is_default = ?',
        whereArgs: [1],
      );
      // Set new default
      await txn.update(
        'editors',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [editorId],
      );
    });
  }

  // ProjectGroup CRUD operations
  Future<int> insertProjectGroup(ProjectGroup group) async {
    final db = await database;
    return await db.insert('project_groups', group.toMap());
  }

  Future<List<ProjectGroup>> getProjectGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('project_groups');
    return List.generate(maps.length, (i) => ProjectGroup.fromMap(maps[i]));
  }

  Future<int> updateProjectGroup(ProjectGroup group) async {
    final db = await database;
    return await db.update(
      'project_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteProjectGroup(int id) async {
    final db = await database;
    return await db.delete(
      'project_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getDistinctGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT group_name FROM projects WHERE group_name IS NOT NULL ORDER BY group_name',
    );
    return maps.map((map) => map['group_name'] as String).toList();
  }
}