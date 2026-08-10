import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._internal();

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
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREAR BASE DE DATOS
  // ============================================================

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

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account_id INTEGER,
        destination_account_id INTEGER,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (destination_account_id) REFERENCES accounts(id)
      )
    ''');
  }

  // ============================================================
  // ACTUALIZAR BASE DE DATOS
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          account_id INTEGER,
          destination_account_id INTEGER,
          category TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id),
          FOREIGN KEY (destination_account_id) REFERENCES accounts(id)
        )
      ''');
    }
  }

  // ============================================================
  // CUENTAS
  // ============================================================

  Future<int> insertAccount(
    Account account,
  ) async {
    final db = await database;

    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
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

  Future<int> updateAccount(
    Account account,
  ) async {
    final db = await database;

    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // APLICAR MOVIMIENTO A LOS SALDOS
  // ============================================================

  Future<void> _applyTransaction(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
    // INGRESO
    if (transaction.type == 'ingreso') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }
    }

    // GASTO
    else if (transaction.type == 'gasto') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance - ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }
    }

    // TRANSFERENCIA
    else if (transaction.type ==
        'transferencia') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance - ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }

      if (transaction.destinationAccountId !=
          null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.destinationAccountId,
          ],
        );
      }
    }
  }

  // ============================================================
  // REVERTIR MOVIMIENTO
  // ============================================================

  Future<void> _reverseTransaction(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
    // INGRESO
    if (transaction.type == 'ingreso') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance - ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }
    }

    // GASTO
    else if (transaction.type == 'gasto') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }
    }

    // TRANSFERENCIA
    else if (transaction.type ==
        'transferencia') {
      if (transaction.accountId != null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance + ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.accountId,
          ],
        );
      }

      if (transaction.destinationAccountId !=
          null) {
        await db.rawUpdate(
          '''
          UPDATE accounts
          SET balance = balance - ?
          WHERE id = ?
          ''',
          [
            transaction.amount,
            transaction.destinationAccountId,
          ],
        );
      }
    }
  }

  // ============================================================
  // INSERTAR MOVIMIENTO
  // ============================================================

  Future<int> insertTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    return await db.transaction(
      (txn) async {
        final transactionId =
            await txn.insert(
          'transactions',
          transaction.toMap(),
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );

        await _applyTransaction(
          txn,
          transaction,
        );

        return transactionId;
      },
    );
  }

  // ============================================================
  // OBTENER MOVIMIENTOS
  // ============================================================

  Future<List<TransactionModel>>
      getTransactions() async {
    final db = await database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return result
        .map(
          (map) =>
              TransactionModel.fromMap(map),
        )
        .toList();
  }

  // ============================================================
  // OBTENER UN MOVIMIENTO
  // ============================================================

  Future<TransactionModel?>
      getTransactionById(int id) async {
    final db = await database;

    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return TransactionModel.fromMap(
      result.first,
    );
  }

  // ============================================================
  // EDITAR MOVIMIENTO
  // ============================================================

  Future<int> updateTransaction(
    TransactionModel transaction,
  ) async {
    if (transaction.id == null) {
      return 0;
    }

    final db = await database;

    return await db.transaction(
      (txn) async {
        final result = await txn.query(
          'transactions',
          where: 'id = ?',
          whereArgs: [transaction.id],
          limit: 1,
        );

        if (result.isEmpty) {
          return 0;
        }

        final oldTransaction =
            TransactionModel.fromMap(
          result.first,
        );

        // Primero deshacemos el movimiento anterior.
        await _reverseTransaction(
          txn,
          oldTransaction,
        );

        // Actualizamos el movimiento.
        final updatedRows =
            await txn.update(
          'transactions',
          transaction.toMap(),
          where: 'id = ?',
          whereArgs: [transaction.id],
        );

        // Aplicamos el nuevo movimiento.
        await _applyTransaction(
          txn,
          transaction,
        );

        return updatedRows;
      },
    );
  }

  // ============================================================
  // ELIMINAR MOVIMIENTO
  // ============================================================

  Future<int> deleteTransaction(
    int id,
  ) async {
    final db = await database;

    return await db.transaction(
      (txn) async {
        final result = await txn.query(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (result.isEmpty) {
          return 0;
        }

        final transaction =
            TransactionModel.fromMap(
          result.first,
        );

        // Primero revertimos el efecto
        // sobre las cuentas.
        await _reverseTransaction(
          txn,
          transaction,
        );

        // Después eliminamos el movimiento.
        return await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
        );
      },
    );
  }
}