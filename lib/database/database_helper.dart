import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../models/credit_card.dart';
import '../models/credit_card_purchase.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  // ============================================================
  // DATABASE
  // ============================================================

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
      version: 3,
      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
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
    // ----------------------------------------------------------
    // CUENTAS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // MOVIMIENTOS
    // ----------------------------------------------------------

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

        FOREIGN KEY (account_id)
          REFERENCES accounts(id),

        FOREIGN KEY (destination_account_id)
          REFERENCES accounts(id)
      )
    ''');

    // ----------------------------------------------------------
    // TARJETAS DE CRÉDITO
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE credit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        bank TEXT NOT NULL,
        credit_limit REAL NOT NULL,
        used_amount REAL NOT NULL,
        cutoff_day INTEGER,
        payment_due_day INTEGER,
        minimum_payment REAL NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // COMPRAS DE TARJETAS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE credit_card_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        credit_card_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        installments INTEGER NOT NULL,
        annual_effective_rate REAL NOT NULL,
        paid_amount REAL NOT NULL,

        FOREIGN KEY (credit_card_id)
          REFERENCES credit_cards(id)
          ON DELETE CASCADE
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
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE credit_cards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          bank TEXT NOT NULL,
          credit_limit REAL NOT NULL,
          used_amount REAL NOT NULL,
          cutoff_day INTEGER,
          payment_due_day INTEGER,
          minimum_payment REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE credit_card_purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          credit_card_id INTEGER NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          purchase_date TEXT NOT NULL,
          installments INTEGER NOT NULL,
          annual_effective_rate REAL NOT NULL,
          paid_amount REAL NOT NULL,

          FOREIGN KEY (credit_card_id)
            REFERENCES credit_cards(id)
            ON DELETE CASCADE
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

  Future<Account?> getAccountById(
    int id,
  ) async {
    final db = await database;

    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Account.fromMap(
      result.first,
    );
  }

  Future<int> updateAccount(
    Account account,
  ) async {
    if (account.id == null) {
      return 0;
    }

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
  // APLICAR MOVIMIENTO
  // ============================================================

  Future<void> _applyTransaction(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
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

    else if (transaction.type == 'transferencia') {
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

      if (transaction.destinationAccountId != null) {
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

    else if (transaction.type == 'transferencia') {
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

      if (transaction.destinationAccountId != null) {
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
  // OBTENER MOVIMIENTO POR ID
  // ============================================================

  Future<TransactionModel?>
      getTransactionById(
    int id,
  ) async {
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
  // ACTUALIZAR MOVIMIENTO
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
        final result =
            await txn.query(
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

        // Primero quitar el efecto anterior.
        await _reverseTransaction(
          txn,
          oldTransaction,
        );

        // Actualizar movimiento.
        final updatedRows =
            await txn.update(
          'transactions',
          transaction.toMap(),
          where: 'id = ?',
          whereArgs: [transaction.id],
        );

        if (updatedRows == 0) {
          return 0;
        }

        // Aplicar el nuevo efecto.
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
        final result =
            await txn.query(
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

        // Revertir efecto sobre la cuenta.
        await _reverseTransaction(
          txn,
          transaction,
        );

        // Eliminar movimiento.
        return await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
        );
      },
    );
  }

  // ============================================================
  // TARJETAS
  // ============================================================

  Future<int> insertCreditCard(
    CreditCard card,
  ) async {
    final db = await database;

    return await db.insert(
      'credit_cards',
      card.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // ============================================================
  // OBTENER TARJETAS
  // ============================================================

  Future<List<CreditCard>>
      getCreditCards() async {
    final db = await database;

    final result = await db.query(
      'credit_cards',
      orderBy: 'id ASC',
    );

    return result
        .map(
          (map) =>
              CreditCard.fromMap(map),
        )
        .toList();
  }

  // ============================================================
  // OBTENER TARJETA
  // ============================================================

  Future<CreditCard?>
      getCreditCardById(
    int id,
  ) async {
    final db = await database;

    final result = await db.query(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return CreditCard.fromMap(
      result.first,
    );
  }

  // ============================================================
  // ACTUALIZAR TARJETA
  // ============================================================

  Future<int> updateCreditCard(
    CreditCard card,
  ) async {
    if (card.id == null) {
      return 0;
    }

    final db = await database;

    return await db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // ============================================================
  // ELIMINAR TARJETA
  // ============================================================

  Future<int> deleteCreditCard(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // INSERTAR COMPRA
  // ============================================================

  Future<int> insertCreditCardPurchase(
    CreditCardPurchase purchase,
  ) async {
    final db = await database;

    return await db.transaction(
      (txn) async {
        // Verificar que exista la tarjeta.
        final cardResult =
            await txn.query(
          'credit_cards',
          where: 'id = ?',
          whereArgs: [
            purchase.creditCardId,
          ],
          limit: 1,
        );

        if (cardResult.isEmpty) {
          return 0;
        }

        final card =
            CreditCard.fromMap(
          cardResult.first,
        );

        // No permitir compras superiores
        // al cupo disponible.
        if (purchase.remainingAmount >
            card.availableCredit) {
          return 0;
        }

        final purchaseId =
            await txn.insert(
          'credit_card_purchases',
          purchase.toMap(),
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );

        // Aumentar cupo utilizado.
        await txn.rawUpdate(
          '''
          UPDATE credit_cards
          SET used_amount =
              used_amount + ?
          WHERE id = ?
          ''',
          [
            purchase.remainingAmount,
            purchase.creditCardId,
          ],
        );

        return purchaseId;
      },
    );
  }

  // ============================================================
  // OBTENER TODAS LAS COMPRAS
  // ============================================================

  Future<List<CreditCardPurchase>>
      getCreditCardPurchases() async {
    final db = await database;

    final result =
        await db.query(
      'credit_card_purchases',
      orderBy:
          'purchase_date DESC',
    );

    return result
        .map(
          (map) =>
              CreditCardPurchase.fromMap(
            map,
          ),
        )
        .toList();
  }

  // ============================================================
  // OBTENER COMPRAS DE UNA TARJETA
  // ============================================================

  Future<List<CreditCardPurchase>>
      getPurchasesByCreditCard(
    int creditCardId,
  ) async {
    final db = await database;

    final result =
        await db.query(
      'credit_card_purchases',
      where:
          'credit_card_id = ?',
      whereArgs: [
        creditCardId,
      ],
      orderBy:
          'purchase_date DESC',
    );

    return result
        .map(
          (map) =>
              CreditCardPurchase.fromMap(
            map,
          ),
        )
        .toList();
  }

  // ============================================================
  // OBTENER COMPRA
  // ============================================================

  Future<CreditCardPurchase?>
      getCreditCardPurchaseById(
    int id,
  ) async {
    final db = await database;

    final result =
        await db.query(
      'credit_card_purchases',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return CreditCardPurchase.fromMap(
      result.first,
    );
  }

  // ============================================================
  // ACTUALIZAR COMPRA
  // ============================================================

  Future<int> updateCreditCardPurchase(
    CreditCardPurchase purchase,
  ) async {
    if (purchase.id == null) {
      return 0;
    }

    final db = await database;

    return await db.transaction(
      (txn) async {
        // Obtener compra anterior.
        final result =
            await txn.query(
          'credit_card_purchases',
          where: 'id = ?',
          whereArgs: [
            purchase.id,
          ],
          limit: 1,
        );

        if (result.isEmpty) {
          return 0;
        }

        final oldPurchase =
            CreditCardPurchase.fromMap(
          result.first,
        );

        // Si cambió de tarjeta.
        if (oldPurchase.creditCardId !=
            purchase.creditCardId) {
          // Verificar tarjeta nueva.
          final newCardResult =
              await txn.query(
            'credit_cards',
            where: 'id = ?',
            whereArgs: [
              purchase.creditCardId,
            ],
            limit: 1,
          );

          if (newCardResult.isEmpty) {
            return 0;
          }

          final newCard =
              CreditCard.fromMap(
            newCardResult.first,
          );

          // Liberar cupo de tarjeta anterior.
          await txn.rawUpdate(
            '''
            UPDATE credit_cards
            SET used_amount =
                CASE
                  WHEN used_amount - ? < 0
                  THEN 0
                  ELSE used_amount - ?
                END
            WHERE id = ?
            ''',
            [
              oldPurchase.remainingAmount,
              oldPurchase.remainingAmount,
              oldPurchase.creditCardId,
            ],
          );

          // Verificar cupo de tarjeta nueva.
          if (purchase.remainingAmount >
              newCard.availableCredit) {
            return 0;
          }

          // Ocupar cupo de tarjeta nueva.
          await txn.rawUpdate(
            '''
            UPDATE credit_cards
            SET used_amount =
                used_amount + ?
            WHERE id = ?
            ''',
            [
              purchase.remainingAmount,
              purchase.creditCardId,
            ],
          );
        }

        // Si continúa en la misma tarjeta.
        else {
          final difference =
              purchase.remainingAmount -
                  oldPurchase.remainingAmount;

          if (difference > 0) {
            final cardResult =
                await txn.query(
              'credit_cards',
              where: 'id = ?',
              whereArgs: [
                purchase.creditCardId,
              ],
              limit: 1,
            );

            if (cardResult.isEmpty) {
              return 0;
            }

            final card =
                CreditCard.fromMap(
              cardResult.first,
            );

            if (difference >
                card.availableCredit) {
              return 0;
            }
          }

          await txn.rawUpdate(
            '''
            UPDATE credit_cards
            SET used_amount =
                CASE
                  WHEN used_amount + ? < 0
                  THEN 0
                  ELSE used_amount + ?
                END
            WHERE id = ?
            ''',
            [
              difference,
              difference,
              purchase.creditCardId,
            ],
          );
        }

        // Actualizar compra.
        return await txn.update(
          'credit_card_purchases',
          purchase.toMap(),
          where: 'id = ?',
          whereArgs: [
            purchase.id,
          ],
        );
      },
    );
  }

  // ============================================================
  // ELIMINAR COMPRA
  // ============================================================

  Future<int> deleteCreditCardPurchase(
    int id,
  ) async {
    final db = await database;

    return await db.transaction(
      (txn) async {
        final result =
            await txn.query(
          'credit_card_purchases',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (result.isEmpty) {
          return 0;
        }

        final purchase =
            CreditCardPurchase.fromMap(
          result.first,
        );

        // Liberar únicamente el saldo pendiente.
        await txn.rawUpdate(
          '''
          UPDATE credit_cards
          SET used_amount =
              CASE
                WHEN used_amount - ? < 0
                THEN 0
                ELSE used_amount - ?
              END
          WHERE id = ?
          ''',
          [
            purchase.remainingAmount,
            purchase.remainingAmount,
            purchase.creditCardId,
          ],
        );

        return await txn.delete(
          'credit_card_purchases',
          where: 'id = ?',
          whereArgs: [id],
        );
      },
    );
  }

  // ============================================================
  // REGISTRAR PAGO DE UNA COMPRA
  // ============================================================

  Future<int> registerCreditCardPayment({
    required int purchaseId,
    required double paymentAmount,
    required int accountId,
  }) async {
    if (paymentAmount <= 0) {
      return 0;
    }

    final db = await database;

    return await db.transaction(
      (txn) async {
        // ------------------------------------------------------
        // OBTENER COMPRA
        // ------------------------------------------------------

        final purchaseResult =
            await txn.query(
          'credit_card_purchases',
          where: 'id = ?',
          whereArgs: [
            purchaseId,
          ],
          limit: 1,
        );

        if (purchaseResult.isEmpty) {
          return 0;
        }

        final purchase =
            CreditCardPurchase.fromMap(
          purchaseResult.first,
        );

        // ------------------------------------------------------
        // SALDO PENDIENTE
        // ------------------------------------------------------

        final remaining =
            purchase.remainingAmount;

        if (remaining <= 0) {
          return 0;
        }

        // ------------------------------------------------------
        // OBTENER CUENTA
        // ------------------------------------------------------

        final accountResult =
            await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [
            accountId,
          ],
          limit: 1,
        );

        if (accountResult.isEmpty) {
          return 0;
        }

        final account =
            Account.fromMap(
          accountResult.first,
        );

        // ------------------------------------------------------
        // VALOR REAL DEL PAGO
        // ------------------------------------------------------

        final amountToPay =
            paymentAmount > remaining
                ? remaining
                : paymentAmount;

        // ------------------------------------------------------
        // VERIFICAR SALDO
        // ------------------------------------------------------

        if (account.balance < amountToPay) {
          return 0;
        }

        // ------------------------------------------------------
        // NUEVO TOTAL PAGADO
        // ------------------------------------------------------

        final newPaidAmount =
            purchase.paidAmount +
                amountToPay;

        // ------------------------------------------------------
        // DESCONTAR DINERO DE LA CUENTA
        // ------------------------------------------------------

        final accountUpdated =
            await txn.rawUpdate(
          '''
          UPDATE accounts
          SET balance =
              balance - ?
          WHERE id = ?
            AND balance >= ?
          ''',
          [
            amountToPay,
            accountId,
            amountToPay,
          ],
        );

        if (accountUpdated == 0) {
          return 0;
        }

        // ------------------------------------------------------
        // ACTUALIZAR COMPRA
        // ------------------------------------------------------

        final purchaseUpdated =
            await txn.update(
          'credit_card_purchases',
          {
            'paid_amount':
                newPaidAmount,
          },
          where: 'id = ?',
          whereArgs: [
            purchaseId,
          ],
        );

        if (purchaseUpdated == 0) {
          return 0;
        }

        // ------------------------------------------------------
        // REDUCIR CUPO UTILIZADO
        // ------------------------------------------------------

        final cardUpdated =
            await txn.rawUpdate(
          '''
          UPDATE credit_cards
          SET used_amount =
              CASE
                WHEN used_amount - ? < 0
                THEN 0
                ELSE used_amount - ?
              END
          WHERE id = ?
          ''',
          [
            amountToPay,
            amountToPay,
            purchase.creditCardId,
          ],
        );

        if (cardUpdated == 0) {
          return 0;
        }

        // ------------------------------------------------------
        // REGISTRAR MOVIMIENTO
        // ------------------------------------------------------

        final now =
            DateTime.now().toIso8601String();

        await txn.insert(
          'transactions',
          {
            'type': 'gasto',
            'amount': amountToPay,
            'account_id': accountId,
            'destination_account_id':
                null,
            'category':
                'Pago tarjeta de crédito',
            'description':
                'Pago de ${purchase.description}',
            'date': now,
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );

        // ------------------------------------------------------
        // ÉXITO
        // ------------------------------------------------------

        return 1;
      },
    );
  }
}