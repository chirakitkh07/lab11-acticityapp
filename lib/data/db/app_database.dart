import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('activity_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        event_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        minutes_before INTEGER NOT NULL,
        remind_at TEXT NOT NULL,
        is_enabled INTEGER NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    // Insert some default categories
    final now = DateTime.now().toIso8601String();
    await db.insert('categories', {
      'name': 'Meeting',
      'color_hex': '0xFF2196F3', // Blue
      'icon_key': 'group',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('categories', {
      'name': 'Training',
      'color_hex': '0xFF4CAF50', // Green
      'icon_key': 'school',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('categories', {
      'name': 'External Task',
      'color_hex': '0xFFE91E63', // Pink
      'icon_key': 'directions_car',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('categories', {
      'name': 'Document Work',
      'color_hex': '0xFFFF9800', // Orange
      'icon_key': 'description',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
