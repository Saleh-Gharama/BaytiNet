import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/usage_data.dart';
import '../models/wifi_session.dart';

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
      version: 5,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Optimization: Enable WAL mode and set synchronous to NORMAL
  // This improves write performance and allows concurrent reads/writes
  Future _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (e) {
      // Ignore or log error appropriately
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE usage ADD COLUMN ssid TEXT NOT NULL DEFAULT 'Unknown'");
    }
    if (oldVersion < 3) {
      // Optimization: Add index on timestamp for faster range queries and cleanup
      await db.execute('CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage (timestamp)');
    }
    if (oldVersion < 4) {
      // Create daily_summary table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_summary (
          date TEXT,
          ssid TEXT,
          usageBytes INTEGER NOT NULL,
          PRIMARY KEY (date, ssid)
        )
      ''');
      // Populate daily_summary with existing data grouped by day and SSID
      try {
        await db.execute('''
          INSERT OR IGNORE INTO daily_summary (date, ssid, usageBytes)
          SELECT 
            strftime('%Y-%m-%d', datetime(timestamp / 1000, 'unixepoch', 'localtime')) as date,
            ssid,
            SUM(usageBytes) as usageBytes
          FROM usage
          GROUP BY date, ssid
        ''');
      } catch (e) {
        // Log or handle migration error
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wifi_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ssid TEXT NOT NULL,
          bssid TEXT,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          bytes_used INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON wifi_sessions (start_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_end_time ON wifi_sessions (end_time)');
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
    // Optimization: Add index on timestamp for faster range queries and cleanup
    await db.execute('CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage (timestamp)');

    // Create daily_summary table
    await db.execute('''
      CREATE TABLE daily_summary (
        date TEXT,
        ssid TEXT,
        usageBytes INTEGER NOT NULL,
        PRIMARY KEY (date, ssid)
      )
    ''');

    // Create wifi_sessions table
    await db.execute('''
      CREATE TABLE wifi_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ssid TEXT NOT NULL,
        bssid TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        bytes_used INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON wifi_sessions (start_time)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_end_time ON wifi_sessions (end_time)');
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

  Future<int> getLastUsageTimestamp() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usage',
      columns: ['timestamp'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['timestamp'] as int;
    }
    return 0;
  }

  // Insert or update daily summary totals
  Future<void> upsertDailySummary(String date, String ssid, int usageBytes) async {
    Database db = await database;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(
        'daily_summary',
        where: 'date = ? AND ssid = ?',
        whereArgs: [date, ssid],
      );
      if (maps.isEmpty) {
        await txn.insert('daily_summary', {
          'date': date,
          'ssid': ssid,
          'usageBytes': usageBytes,
        });
      } else {
        final currentBytes = maps.first['usageBytes'] as int;
        await txn.update(
          'daily_summary',
          {'usageBytes': currentBytes + usageBytes},
          where: 'date = ? AND ssid = ?',
          whereArgs: [date, ssid],
        );
      }
    });
  }

  // Get daily usage grouped by day for a specific month (format: YYYY-MM)
  Future<List<Map<String, dynamic>>> getDailySummaryForMonth(String yearMonth) async {
    Database db = await database;
    return await db.query(
      'daily_summary',
      where: "date LIKE ?",
      whereArgs: ['$yearMonth-%'],
      orderBy: 'date ASC',
    );
  }

  // Get daily usage between two dates (format: YYYY-MM-DD)
  Future<List<Map<String, dynamic>>> getDailySummaryInRange(String startDate, String endDate) async {
    Database db = await database;
    return await db.query(
      'daily_summary',
      where: "date >= ? AND date <= ?",
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  // Get hourly usage for a specific day (format: YYYY-MM-DD)
  Future<List<Map<String, dynamic>>> getHourlySummaryForDay(String date) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        strftime('%H', datetime(timestamp / 1000, 'unixepoch', 'localtime')) as hour,
        SUM(usageBytes) as usageBytes
      FROM usage
      WHERE strftime('%Y-%m-%d', datetime(timestamp / 1000, 'unixepoch', 'localtime')) = ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [date]);
  }

  // Get monthly totals and list of months
  Future<List<Map<String, dynamic>>> getMonthlyUsageHistory() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        substr(date, 1, 7) as month,
        SUM(usageBytes) as totalUsage
      FROM daily_summary
      GROUP BY month
      ORDER BY month DESC
    ''');
  }

  // --- Wi-Fi Sessions Management (Hybrid Tracking) ---

  Future<int> insertWifiSession(WifiSession session) async {
    Database db = await database;
    return await db.insert('wifi_sessions', session.toMap());
  }

  Future<WifiSession?> getActiveWifiSession() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wifi_sessions',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WifiSession.fromMap(maps.first);
    }
    return null;
  }

  Future<void> closeWifiSession(int id, int endTime, int bytesUsed) async {
    Database db = await database;
    await db.update(
      'wifi_sessions',
      {
        'end_time': endTime,
        'bytes_used': bytesUsed,
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateWifiSessionBytes(int id, int bytesUsed, {bool isSynced = false}) async {
    Database db = await database;
    await db.update(
      'wifi_sessions',
      {
        'bytes_used': bytesUsed,
        'is_synced': isSynced ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WifiSession>> getUnsyncedSessions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wifi_sessions',
      where: 'is_synced = 0 AND end_time IS NOT NULL',
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => WifiSession.fromMap(maps[i]));
  }

  Future<List<WifiSession>> getSessionsInRange(int startTime, int endTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wifi_sessions',
      where: 'start_time <= ? AND (end_time >= ? OR end_time IS NULL)',
      whereArgs: [endTime, startTime],
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => WifiSession.fromMap(maps[i]));
  }

  Future<Map<String, int>> getUsageBySsidFromSessionsInRange(int startTime, int endTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ssid, SUM(bytes_used) as totalUsage
      FROM wifi_sessions
      WHERE start_time <= ? AND (end_time >= ? OR end_time IS NULL)
      GROUP BY ssid
      ORDER BY totalUsage DESC
    ''', [endTime, startTime]);

    Map<String, int> result = {};
    for (var map in maps) {
      final ssid = map['ssid'] as String? ?? 'Unknown';
      final usage = (map['totalUsage'] as int?) ?? 0;
      if (usage > 0) {
        result[ssid] = usage;
      }
    }
    return result;
  }
}

