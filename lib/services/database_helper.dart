import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/usage_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'baytinet.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        usageBytes INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertUsage(UsageData data) async {
    Database db = await database;
    return await db.insert('usage', data.toMap());
  }

  Future<List<UsageData>> getUsageInRange(int startTime, int endTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usage',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startTime, endTime],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => UsageData.fromMap(maps[i]));
  }

  Future<void> deleteOldData(int olderThanTimestamp) async {
    Database db = await database;
    await db.delete(
      'usage',
      where: 'timestamp < ?',
      whereArgs: [olderThanTimestamp],
    );
  }
}
