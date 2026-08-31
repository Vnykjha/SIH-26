import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/screening.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'crepisense_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE screenings (
        screening_id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        sex TEXT NOT NULL,
        occupation TEXT NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        bmi REAL NOT NULL,
        prior_injury_history INTEGER NOT NULL,
        injury_notes TEXT,
        preferred_language TEXT NOT NULL,
        camp_id TEXT NOT NULL,
        district TEXT NOT NULL,
        pain_score INTEGER NOT NULL,
        stiffness_score INTEGER NOT NULL,
        function_score INTEGER NOT NULL,
        total_womac_score INTEGER NOT NULL,
        responses_raw_json TEXT NOT NULL,
        test_type TEXT NOT NULL,
        test_variant TEXT NOT NULL,
        duration_seconds REAL NOT NULL,
        peak_accel REAL NOT NULL,
        accel_variance REAL NOT NULL,
        cadence_cps REAL NOT NULL,
        kinetic_energy REAL NOT NULL,
        imu_puck_features_json TEXT,
        risk_level TEXT NOT NULL,
        confidence REAL NOT NULL,
        model_version TEXT NOT NULL,
        computed_at TEXT NOT NULL,
        screening_mode TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_screenings_synced ON screenings(synced)');
    await db.execute('CREATE INDEX idx_screenings_patient ON screenings(patient_id)');
    await db.execute('CREATE INDEX idx_screenings_created ON screenings(created_at)');
  }

  Future<int> insertScreening(Screening screening) async {
    final db = await instance.database;
    return await db.insert(
      'screenings',
      screening.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Screening?> getScreeningById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'screenings',
      where: 'screening_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Screening.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Screening>> getAllScreenings({int limit = 50, int offset = 0}) async {
    final db = await instance.database;
    final maps = await db.query(
      'screenings',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Screening.fromMap(map)).toList();
  }

  Future<List<Screening>> getUnsyncedScreenings() async {
    final db = await instance.database;
    final maps = await db.query(
      'screenings',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => Screening.fromMap(map)).toList();
  }

  Future<int> markAsSynced(List<String> screeningIds) async {
    if (screeningIds.isEmpty) return 0;
    final db = await instance.database;
    final placeholders = List.filled(screeningIds.length, '?').join(',');

    return await db.update(
      'screenings',
      {'synced': 1},
      where: 'screening_id IN ($placeholders)',
      whereArgs: screeningIds,
    );
  }

  Future<Map<String, int>> getRiskCounts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT risk_level, COUNT(*) as count
      FROM screenings
      GROUP BY risk_level
    ''');

    final counts = <String, int>{'Low': 0, 'Medium': 0, 'High': 0};
    for (final row in result) {
      final level = row['risk_level'] as String;
      final count = row['count'] as int;
      counts[level] = count;
    }
    return counts;
  }
}
