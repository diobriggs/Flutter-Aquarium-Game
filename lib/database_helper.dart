import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();

  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aquarium.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fishSpeed REAL,
        fishColor INTEGER,
        fishCount INTEGER
      )
    ''');
  }

  Future<void> saveSettings(double fishSpeed, int fishColor, int fishCount) async {
    final db = await instance.database;

    await db.insert('settings', {
      'fishSpeed': fishSpeed,    // Save the speed
      'fishColor': fishColor,    // Save the color in int format
      'fishCount': fishCount,    // Save the count
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final db = await instance.database;

    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
