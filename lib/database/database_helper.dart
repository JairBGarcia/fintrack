import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'fintrack.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');
  }

  Future<int> insertAccount(Account account) async {
    final db = await database;

    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;

    final result = await db.query(
      'accounts',
      orderBy: 'id ASC',
    );

    return result
        .map(
          (map) => Account.fromMap(map),
        )
        .toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;

    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;

    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}