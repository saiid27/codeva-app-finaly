import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalApi {
  LocalApi._();
  static final LocalApi instance = LocalApi._();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) {
      await _ensureSchema(_db!);
      await _ensureDefaults(_db!);
      return _db!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'presence_qr_local.db');
    _db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE companies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL DEFAULT 'active',
            latitude REAL NOT NULL DEFAULT 18.0735,
            longitude REAL NOT NULL DEFAULT -15.9582,
            radius_m REAL NOT NULL DEFAULT 150
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            phone TEXT,
            job_title TEXT,
            role TEXT NOT NULL,
            status TEXT NOT NULL,
            company_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            attend_date TEXT NOT NULL,
            status TEXT NOT NULL,
            time TEXT,
            latitude REAL,
            longitude REAL,
            distance_m REAL,
            verification_reason TEXT,
            UNIQUE(user_id, attend_date)
          )
        ''');
        await db.execute('''
          CREATE TABLE email_otps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            code TEXT NOT NULL,
            expires_at INTEGER NOT NULL,
            used INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            company_id INTEGER,
            url TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureSchema(db);
      },
      onOpen: _ensureSchema,
    );
    await _ensureDefaults(_db!);
    return _db!;
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'active',
        latitude REAL NOT NULL DEFAULT 18.0735,
        longitude REAL NOT NULL DEFAULT -15.9582,
        radius_m REAL NOT NULL DEFAULT 150
      )
    ''');
    await _addColumnIfMissing(db, 'users', 'phone', 'TEXT');
    await _addColumnIfMissing(db, 'users', 'job_title', 'TEXT');
    await _addColumnIfMissing(db, 'users', 'company_id', 'INTEGER');
    await _addColumnIfMissing(db, 'attendance', 'latitude', 'REAL');
    await _addColumnIfMissing(db, 'attendance', 'longitude', 'REAL');
    await _addColumnIfMissing(db, 'attendance', 'distance_m', 'REAL');
    await _addColumnIfMissing(db, 'attendance', 'verification_reason', 'TEXT');
    await _addColumnIfMissing(db, 'locations', 'company_id', 'INTEGER');
  }

  Future<void> _ensureDefaults(Database db) async {
    await db.delete('users', where: 'email = ? ', whereArgs: ['admin@local']);
    await db.insert('companies', {
      'name': 'CODEVA',
      'status': 'active',
      'latitude': 18.0735,
      'longitude': -15.9582,
      'radius_m': 150,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final defaultCompany = (await db.query(
      'companies',
      where: 'name = ? ',
      whereArgs: ['CODEVA'],
      limit: 1,
    )).first;
    final defaultCompanyId = defaultCompany['id'] as int;

    final admin = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: ['admin@gmail.com'],
      limit: 1,
    );
    if (admin.isEmpty) {
      await db.insert('users', {
        'full_name': 'Admin',
        'email': 'admin@gmail.com',
        'password_hash': 'codeva123',
        'phone': '',
        'job_title': 'Admin',
        'role': 'admin',
        'status': 'approved',
        'company_id': defaultCompanyId,
      });
    } else {
      await db.update(
        'users',
        {
          'password_hash': 'codeva123',
          'role': 'admin',
          'status': 'approved',
          'company_id': defaultCompanyId,
        },
        where: 'email = ? ',
        whereArgs: ['admin@gmail.com'],
      );
    }
    final developer = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: ['developer@codeva.local'],
      limit: 1,
    );
    if (developer.isEmpty) {
      await db.insert('users', {
        'full_name': 'Developer',
        'email': 'developer@codeva.local',
        'password_hash': 'codeva123',
        'phone': '',
        'job_title': 'Developer',
        'role': 'developer',
        'status': 'approved',
        'company_id': null,
      });
    }
    await db.update(
      'users',
      {'company_id': defaultCompanyId},
      where: 'company_id IS NULL AND role <> ?',
      whereArgs: ['developer'],
    );

    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (count <= 2) {
      await db.insert('users', {
        'full_name': 'User Demo',
        'email': 'user1@local',
        'password_hash': '1234',
        'phone': '',
        'job_title': 'Groupe A',
        'role': 'worker',
        'status': 'approved',
        'company_id': defaultCompanyId,
      });
      await db.insert('users', {
        'full_name': 'User Pending',
        'email': 'user2@local',
        'password_hash': '1234',
        'phone': '',
        'job_title': 'Groupe B',
        'role': 'worker',
        'status': 'pending',
        'company_id': defaultCompanyId,
      });
    }
  }

  static const String _attendanceQrToken = 'codeva-presence-checkin';

  Future<Map<String, dynamic>> requestOtp(
    String email, {
    String purpose = 'login',
  }) async {
    final db = await _open();
    if (email.isEmpty) return {'ok': false, 'reason': 'email_required'};
    final existing = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    if (purpose == 'register') {
      if (existing.isNotEmpty) return {'ok': false, 'reason': 'email_exists'};
    } else {
      if (existing.isEmpty) return {'ok': false, 'reason': 'not_found'};
    }

    final code = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    await db.insert('email_otps', {
      'email': email,
      'code': code,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'used': 0,
    });
    return {'ok': true, 'code': code};
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    final db = await _open();
    if (email.isEmpty || code.isEmpty) {
      return {'ok': false, 'reason': 'invalid'};
    }
    final rows = await db.query(
      'email_otps',
      where: 'email = ? AND code = ? AND used = 0',
      whereArgs: [email, code],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return {'ok': false, 'reason': 'invalid'};
    final row = rows.first;
    final expiresAt = row['expires_at'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return {'ok': false, 'reason': 'expired'};
    }
    await db.update(
      'email_otps',
      {'used': 1},
      where: 'id = ? ',
      whereArgs: [row['id']],
    );
    return {'ok': true};
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String otp,
    String? phone,
    String? jobTitle,
  }) async {
    final db = await _open();
    final existing = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) return {'ok': false, 'reason': 'email_exists'};
    if (otp.isNotEmpty) {
      final otpResult = await verifyOtp(email, otp);
      if (otpResult['ok'] != true) {
        return {'ok': false, 'reason': 'otp_invalid'};
      }
    }
    await db.insert('users', {
      'full_name': fullName,
      'email': email,
      'password_hash': password,
      'phone': phone ?? '',
      'job_title': jobTitle ?? '',
      'role': 'worker',
      'status': 'pending',
    });
    return {'ok': true};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String otp,
  }) async {
    final db = await _open();
    if (otp.isNotEmpty) {
      final otpResult = await verifyOtp(email, otp);
      if (otpResult['ok'] != true) {
        return {'ok': false, 'reason': 'otp_invalid'};
      }
    }
    final rows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return {'ok': false, 'reason': 'not_found'};
    final user = rows.first;
    if (user['role'] != 'developer' && user['company_id'] != null) {
      final company = await db.query(
        'companies',
        where: 'id = ? ',
        whereArgs: [user['company_id']],
        limit: 1,
      );
      if (company.isNotEmpty && company.first['status'] == 'frozen') {
        return {'ok': false, 'reason': 'company_frozen'};
      }
    }
    if (user['status'] != 'approved') {
      return {'ok': false, 'reason': user['status']};
    }
    if (user['password_hash'] != password) {
      return {'ok': false, 'reason': 'invalid'};
    }
    return {
      'ok': true,
      'user': {
        'id': user['id'],
        'fullName': user['full_name'],
        'email': user['email'],
        'role': user['role'],
        'companyId': user['company_id'],
      },
    };
  }

  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return {'ok': false, 'reason': 'not_found'};
    final user = rows.first;
    if (user['password_hash'] != oldPassword) {
      return {'ok': false, 'reason': 'invalid'};
    }
    await db.update(
      'users',
      {'password_hash': newPassword},
      where: 'id = ? ',
      whereArgs: [user['id']],
    );
    return {'ok': true};
  }

  Future<Map<String, dynamic>> scanAttendance({
    required String email,
    required String token,
  }) async {
    final db = await _open();
    final userRows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    if (userRows.isEmpty) return {'ok': false, 'reason': 'not_found'};
    final user = userRows.first;
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.query(
      'attendance',
      where: 'user_id = ? AND attend_date = ? ',
      whereArgs: [user['id'], date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return {'ok': true, 'already': true};
    }

    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    await db.insert('attendance', {
      'user_id': user['id'],
      'attend_date': date,
      'status': 'present',
      'time': time,
    });
    return {'ok': true, 'already': false};
  }

  Future<Map<String, dynamic>> qrToday() async {
    return {'token': _attendanceQrToken};
  }

  Future<Map<String, dynamic>> recordLocationAttendance({
    required String email,
    required bool verified,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required String reason,
  }) async {
    final db = await _open();
    final userRows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    if (userRows.isEmpty) return {'ok': false, 'reason': 'not_found'};
    final user = userRows.first;
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.query(
      'attendance',
      where: 'user_id = ? AND attend_date = ? ',
      whereArgs: [user['id'], date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return {'ok': true, 'already': true};
    }

    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    await db.insert('attendance', {
      'user_id': user['id'],
      'attend_date': date,
      'status': verified ? 'present' : 'absent',
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'distance_m': distanceMeters,
      'verification_reason': reason,
    });
    return {'ok': true, 'already': false, 'verified': verified};
  }

  Future<Map<String, dynamic>?> _actor(String? actorEmail) async {
    if (actorEmail == null || actorEmail.isEmpty) return null;
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [actorEmail],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> listUsers(
    String status, {
    String? actorEmail,
  }) async {
    final db = await _open();
    final actor = await _actor(actorEmail);
    if (actor != null && actor['role'] != 'developer') {
      return db.query(
        'users',
        where: 'status = ? AND company_id = ? AND role <> ?',
        whereArgs: [status, actor['company_id'], 'developer'],
      );
    }
    return db.query(
      'users',
      where: 'status = ? AND role <> ?',
      whereArgs: [status, 'developer'],
    );
  }

  Future<void> approveUser(int id) async {
    final db = await _open();
    await db.update(
      'users',
      {'status': 'approved'},
      where: 'id = ? ',
      whereArgs: [id],
    );
  }

  Future<void> rejectUser(int id) async {
    final db = await _open();
    await db.update(
      'users',
      {'status': 'rejected'},
      where: 'id = ? ',
      whereArgs: [id],
    );
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String jobTitle,
    required String role,
    String? actorEmail,
  }) async {
    final db = await _open();
    final actor = await _actor(actorEmail);
    final companyId = actor != null && actor['role'] != 'developer'
        ? actor['company_id']
        : null;
    await db.insert('users', {
      'full_name': fullName,
      'email': email,
      'password_hash': 'Temp1234',
      'phone': phone,
      'job_title': jobTitle,
      'role': role,
      'status': 'pending',
      'company_id': companyId,
    });
  }

  Future<List<Map<String, dynamic>>> listAttendance({
    required String month,
    required String group,
    String? actorEmail,
  }) async {
    final db = await _open();
    final actor = await _actor(actorEmail);
    final whereGroup = group == 'Tous' ? '' : 'AND u.job_title = ? ';
    final whereCompany = actor != null && actor['role'] != 'developer'
        ? 'AND u.company_id = ? '
        : '';
    final args = <Object?>[month];
    if (group != 'Tous') args.add(group);
    if (actor != null && actor['role'] != 'developer') {
      args.add(actor['company_id']);
    }
    return db.rawQuery('''
      SELECT a.attend_date, a.status, a.time, a.latitude, a.longitude,
             a.distance_m, a.verification_reason, u.full_name, u.job_title
      FROM attendance a
      JOIN users u ON a.user_id = u.id
      WHERE substr(a.attend_date,1,7) = ?
      $whereGroup
      $whereCompany
      ORDER BY a.attend_date DESC
    ''', args);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    final exists = rows.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<List<Map<String, dynamic>>> monthlyReport({
    required String month,
    String? actorEmail,
  }) async {
    final db = await _open();
    final actor = await _actor(actorEmail);
    final whereCompany = actor != null && actor['role'] != 'developer'
        ? 'AND u.company_id = ?'
        : '';
    final args = <Object?>[month];
    if (actor != null && actor['role'] != 'developer') {
      args.add(actor['company_id']);
    }
    final rows = await db.rawQuery('''
      SELECT
        u.full_name AS name,
        SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS present,
        SUM(CASE WHEN a.status IS NOT NULL AND a.status <> 'present' THEN 1 ELSE 0 END) AS absent
      FROM users u
      LEFT JOIN attendance a
        ON a.user_id = u.id
       AND a.attend_date LIKE ? || '%'
      WHERE u.role = 'worker'
      $whereCompany
      GROUP BY u.id
      ORDER BY u.full_name COLLATE NOCASE ASC
    ''', args);
    return rows;
  }

  Future<List<Map<String, dynamic>>> listCompanies() async {
    final db = await _open();
    return db.rawQuery('''
      SELECT c.*, COUNT(u.id) AS userCount
      FROM companies c
      LEFT JOIN users u ON u.company_id = c.id AND u.role <> 'developer'
      GROUP BY c.id
      ORDER BY c.id DESC
    ''');
  }

  Future<void> createCompany({
    required String name,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final db = await _open();
    final companyId = await db.insert('companies', {
      'name': name,
      'status': 'active',
      'latitude': 18.0735,
      'longitude': -15.9582,
      'radius_m': 150,
    });
    await db.insert('users', {
      'full_name': adminName,
      'email': adminEmail,
      'password_hash': adminPassword,
      'phone': '',
      'job_title': 'Admin',
      'role': 'admin',
      'status': 'approved',
      'company_id': companyId,
    });
  }

  Future<void> setCompanyStatus(int id, String status) async {
    final db = await _open();
    await db.update(
      'companies',
      {'status': status},
      where: 'id = ? ',
      whereArgs: [id],
    );
  }

  Future<void> addLocation(String email, String url) async {
    final db = await _open();
    final rows = await db.query(
      'users',
      where: 'email = ? ',
      whereArgs: [email],
      limit: 1,
    );
    await db.insert('locations', {
      'email': email,
      'company_id': rows.isEmpty ? null : rows.first['company_id'],
      'url': url,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> listLocations({String? actorEmail}) async {
    final db = await _open();
    final actor = await _actor(actorEmail);
    if (actor != null && actor['role'] != 'developer') {
      return db.query(
        'locations',
        where: 'company_id = ? ',
        whereArgs: [actor['company_id']],
        orderBy: 'id DESC',
      );
    }
    return db.query('locations', orderBy: 'id DESC');
  }
}
