import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/credit_card.dart';
import '../models/credit_card_purchase.dart';
import '../models/transaction.dart';

class PauFinancialContext {
  final List<Account> accounts;
  final List<CreditCard> creditCards;
  final List<CreditCardPurchase> purchases;
  final List<TransactionModel> transactions;

  PauFinancialContext({
    required this.accounts,
    required this.creditCards,
    required this.purchases,
    required this.transactions,
  });

  // ============================================================
  // CARGAR INFORMACIÓN FINANCIERA
  // ============================================================

  static Future<PauFinancialContext> load() async {
    final database =
        DatabaseHelper.instance;

    final accounts =
        await database.getAccounts();

    final creditCards =
        await database.getCreditCards();

    final purchases =
        await database.getCreditCardPurchases();

    final transactions =
        await database.getTransactions();

    return PauFinancialContext(
      accounts: accounts,
      creditCards: creditCards,
      purchases: purchases,
      transactions: transactions,
    );
  }

  // ============================================================
  // DINERO DISPONIBLE
  // ============================================================

  double get totalBalance {
    return accounts.fold(
      0,
      (total, account) =>
          total + account.balance,
    );
  }

  // ============================================================
  // DEUDA DE TARJETAS
  // ============================================================

  double get totalCreditCardDebt {
    return purchases.fold(
      0,
      (total, purchase) =>
          total + purchase.remainingAmount,
    );
  }

  // ============================================================
  // INGRESOS
  // ============================================================

  double get totalIncome {
    return transactions
        .where(
          (transaction) =>
              transaction.type == 'ingreso',
        )
        .fold(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ============================================================
  // GASTOS
  // ============================================================

  double get totalExpenses {
    return transactions
        .where(
          (transaction) =>
              transaction.type == 'gasto',
        )
        .fold(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ============================================================
  // CONTEXTO PARA LA IA
  // ============================================================

  String buildContext() {
    final buffer =
        StringBuffer();

    buffer.writeln(
      'INFORMACIÓN FINANCIERA ACTUAL DEL USUARIO',
    );

    buffer.writeln();

    // ----------------------------------------------------------
    // RESUMEN GENERAL
    // ----------------------------------------------------------

    buffer.writeln(
      'RESUMEN GENERAL:',
    );

    buffer.writeln(
      'Dinero disponible en cuentas: $totalBalance',
    );

    buffer.writeln(
      'Deuda pendiente de compras con tarjeta: $totalCreditCardDebt',
    );

    buffer.writeln(
      'Ingresos registrados: $totalIncome',
    );

    buffer.writeln(
      'Gastos registrados: $totalExpenses',
    );

    buffer.writeln();

    // ----------------------------------------------------------
    // CUENTAS
    // ----------------------------------------------------------

    buffer.writeln(
      'CUENTAS:',
    );

    if (accounts.isEmpty) {
      buffer.writeln(
        'No hay cuentas registradas.',
      );
    } else {
      for (final account in accounts) {
        buffer.writeln(
          '- ${account.name}: ${account.balance} (${account.type})',
        );
      }
    }

    buffer.writeln();

    // ----------------------------------------------------------
    // TARJETAS
    // ----------------------------------------------------------

    buffer.writeln(
      'TARJETAS DE CRÉDITO:',
    );

    if (creditCards.isEmpty) {
      buffer.writeln(
        'No hay tarjetas registradas.',
      );
    } else {
      for (final card in creditCards) {
        buffer.writeln(
          '- ${card.name} (${card.bank}): '
          'cupo total ${card.creditLimit}, '
          'utilizado ${card.usedAmount}, '
          'disponible ${card.availableCredit}',
        );
      }
    }

    buffer.writeln();

    // ----------------------------------------------------------
    // COMPRAS
    // ----------------------------------------------------------

    buffer.writeln(
      'COMPRAS CON TARJETA:',
    );

    if (purchases.isEmpty) {
      buffer.writeln(
        'No hay compras registradas.',
      );
    } else {
      for (final purchase in purchases) {
        buffer.writeln(
          '- ${purchase.description}: '
          'valor ${purchase.amount}, '
          'pagado ${purchase.paidAmount}, '
          'pendiente ${purchase.remainingAmount}, '
          'categoría ${purchase.category}, '
          'cuotas ${purchase.installments}',
        );
      }
    }

    buffer.writeln();

    // ----------------------------------------------------------
    // MOVIMIENTOS
    // ----------------------------------------------------------

    buffer.writeln(
      'MOVIMIENTOS:',
    );

    if (transactions.isEmpty) {
      buffer.writeln(
        'No hay movimientos registrados.',
      );
    } else {
      for (final transaction
          in transactions) {
        buffer.writeln(
          '- ${transaction.type}: '
          '${transaction.amount}, '
          'categoría ${transaction.category}, '
          'descripción ${transaction.description}, '
          'fecha ${transaction.date.toIso8601String()}',
        );
      }
    }

    return buffer.toString();
  }
}