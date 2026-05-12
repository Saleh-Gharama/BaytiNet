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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE usage ADD COLUMN ssid TEXT NOT NULL DEFAULT 'Unknown'");
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        usageBytes INTEGER NOT NULL,
        ssid TEXT NOT NULL DEFAULT 'Unknown'
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

  Future<Map<String, int>> getUsageBySsidInRange(int startTime, int endTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ssid, SUM(usageBytes) as totalUsage
      FROM usage
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY ssid
      ORDER BY totalUsage DESC
    ''', [startTime, endTime]);

    Map<String, int> result = {};
    for (var map in maps) {
      result[map['ssid'] as String] = map['totalUsage'] as int;
    }
    return result;
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
