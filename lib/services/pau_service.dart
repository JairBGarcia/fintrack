import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/credit_card.dart';
import '../models/credit_card_purchase.dart';

class PauService {
  // ============================================================
  // PAU - COACH FINANCIERO
  // ============================================================

  static const String name = 'Pau';

  static const String description =
      'Tu coach financiero personal';

  // ============================================================
  // GROQ
  // ============================================================

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model =
      'openai/gpt-oss-120b';

  // ============================================================
  // ENVIAR MENSAJE
  // ============================================================

  Future<String> sendMessage(String message) async {
    try {
      // --------------------------------------------------------
      // OBTENER DATOS REALES DE FINTRACK
      // --------------------------------------------------------

      final accounts =
          await DatabaseHelper.instance.getAccounts();

      final transactions =
          await DatabaseHelper.instance.getTransactions();

      final creditCards =
          await DatabaseHelper.instance.getCreditCards();

      final purchases =
          await DatabaseHelper.instance
              .getCreditCardPurchases();

      // --------------------------------------------------------
      // CREAR RESUMEN FINANCIERO
      // --------------------------------------------------------

      final financialContext =
          _buildFinancialContext(
        accounts: accounts,
        transactions: transactions,
        creditCards: creditCards,
        purchases: purchases,
      );

      // --------------------------------------------------------
      // LLAMAR A GROQ
      // --------------------------------------------------------

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${ApiConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': _model,

          'messages': [
            // ==================================================
            // SYSTEM
            // ==================================================

            {
              'role': 'system',
              'content': '''
Eres Pau, el coach financiero personal de FinTrack.

Tu trabajo es ayudar al usuario a comprender y organizar
sus finanzas personales utilizando los datos reales que
FinTrack te proporciona.

REGLAS IMPORTANTES:

1. Responde siempre en español.

2. Sé clara, natural, amigable y práctica.

3. Responde de forma CONCISA.
   No escribas respuestas innecesariamente largas.

4. No muestres operaciones matemáticas internas,
   cálculos paso a paso ni procesos de razonamiento.

5. No escribas cosas como:
   "primero calculo...", "entonces hago...",
   "divido esto entre aquello..." o similares.

6. Si necesitas hacer cálculos, hazlos internamente
   y muestra solamente el resultado y una explicación
   breve.

7. Utiliza los datos financieros proporcionados por
   FinTrack para responder.

8. NO inventes cuentas, saldos, movimientos, tarjetas
   ni cantidades que no aparezcan en los datos.

9. Si un dato no está disponible, dilo claramente.

10. Cuando el usuario pregunte por su situación financiera,
    analiza los datos disponibles y proporciona una
    conclusión útil.

11. Puedes identificar patrones de gasto, ingresos,
    saldos, utilización de tarjetas y movimientos.

12. Si detectas algo importante, comunícalo de manera
    sencilla.

13. No prometas resultados financieros.

14. No sustituyes a un asesor financiero profesional.

15. Recuerda que tu nombre es Pau.

DATOS FINANCIEROS DE FINTRACK:

$financialContext
''',
            },

            // ==================================================
            // MENSAJE DEL USUARIO
            // ==================================================

            {
              'role': 'user',
              'content': message,
            },
          ],

          'temperature': 0.5,
        }),
      );

      // ========================================================
      // RESPUESTA EXITOSA
      // ========================================================

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final choices =
            data['choices'] as List?;

        if (choices == null ||
            choices.isEmpty) {
          return 'Pau no recibió una respuesta válida.';
        }

        final messageData =
            choices.first['message'];

        if (messageData == null) {
          return 'Pau no pudo generar una respuesta.';
        }

        final content =
            messageData['content'];

        if (content == null ||
            content.toString().trim().isEmpty) {
          return 'Pau no pudo generar una respuesta.';
        }

        return content
            .toString()
            .trim();
      }

      // ========================================================
      // ERROR DE GROQ
      // ========================================================

      try {
        final errorData =
            jsonDecode(response.body);

        final error =
            errorData['error'];

        if (error != null) {
          final errorMessage =
              error['message'];

          if (errorMessage != null) {
            return 'Pau tuvo un problema: $errorMessage';
          }
        }
      } catch (_) {
        // Ignorar si la respuesta no es JSON.
      }

      return '''
Pau no pudo responder en este momento.

Código del servidor: ${response.statusCode}
''';
    } catch (e) {
      return '''
No se pudo conectar con Pau.

Verifica tu conexión a Internet.
''';
    }
  }

  // ============================================================
  // CONSTRUIR CONTEXTO FINANCIERO
  // ============================================================

  String _buildFinancialContext({
    required List<Account> accounts,
    required List<TransactionModel> transactions,
    required List<CreditCard> creditCards,
    required List<CreditCardPurchase> purchases,
  }) {
    final buffer =
        StringBuffer();

    // ==========================================================
    // RESUMEN GENERAL
    // ==========================================================

    double totalMoney = 0;

    for (final account in accounts) {
      totalMoney += account.balance;
    }

    buffer.writeln(
      'RESUMEN GENERAL',
    );

    buffer.writeln(
      'Total de dinero en cuentas: ${_money(totalMoney)}',
    );

    buffer.writeln(
      'Cantidad de cuentas: ${accounts.length}',
    );

    buffer.writeln(
      'Cantidad de tarjetas: ${creditCards.length}',
    );

    buffer.writeln(
      'Cantidad de movimientos registrados: ${transactions.length}',
    );

    buffer.writeln();

    // ==========================================================
    // CUENTAS
    // ==========================================================

    buffer.writeln(
      'CUENTAS',
    );

    if (accounts.isEmpty) {
      buffer.writeln(
        'No hay cuentas registradas.',
      );
    } else {
      for (final account in accounts) {
        buffer.writeln(
          '- ${account.name} | '
          'Tipo: ${account.type} | '
          'Saldo: ${_money(account.balance)} | '
          'ID: ${account.id}',
        );
      }
    }

    buffer.writeln();

    // ==========================================================
    // TARJETAS
    // ==========================================================

    buffer.writeln(
      'TARJETAS DE CRÉDITO',
    );

    if (creditCards.isEmpty) {
      buffer.writeln(
        'No hay tarjetas registradas.',
      );
    } else {
      for (final card in creditCards) {
        buffer.writeln(
          '- ${card.name} | '
          'Banco: ${card.bank} | '
          'Cupo: ${_money(card.creditLimit)} | '
          'Utilizado: ${_money(card.usedAmount)} | '
          'Disponible: ${_money(card.availableCredit)} | '
          'Uso: ${card.usagePercentage.toStringAsFixed(1)}%',
        );

        if (card.cutoffDay != null) {
          buffer.writeln(
            '  Corte: día ${card.cutoffDay}',
          );
        }

        if (card.paymentDueDay != null) {
          buffer.writeln(
            '  Pago: día ${card.paymentDueDay}',
          );
        }

        buffer.writeln(
          '  Pago mínimo: ${_money(card.minimumPayment)}',
        );
      }
    }

    buffer.writeln();

    // ==========================================================
    // MOVIMIENTOS
    // ==========================================================

    buffer.writeln(
      'MOVIMIENTOS',
    );

    if (transactions.isEmpty) {
      buffer.writeln(
        'No hay movimientos registrados.',
      );
    } else {
      // Mostrar los movimientos más recientes.
      //
      // Limitamos a 50 para no mandar cantidades
      // innecesarias de información a la IA.

      final recentTransactions =
          transactions.length > 50
              ? transactions.take(50)
              : transactions;

      for (final transaction
          in recentTransactions) {
        final accountName =
            _getAccountName(
          accounts,
          transaction.accountId,
        );

        final destinationName =
            _getAccountName(
          accounts,
          transaction.destinationAccountId,
        );

        buffer.write(
          '- ${transaction.date} | '
          'Tipo: ${transaction.type} | '
          'Valor: ${_money(transaction.amount)} | '
          'Categoría: ${transaction.category}',
        );

        if (transaction.description != null &&
            transaction.description!
                .trim()
                .isNotEmpty) {
          buffer.write(
            ' | Descripción: '
            '${transaction.description}',
          );
        }

        if (transaction.accountId != null) {
          buffer.write(
            ' | Cuenta: $accountName',
          );
        }

        if (transaction.destinationAccountId !=
            null) {
          buffer.write(
            ' | Destino: $destinationName',
          );
        }

        buffer.writeln();
      }
    }

    buffer.writeln();

    // ==========================================================
    // COMPRAS DE TARJETAS
    // ==========================================================

    buffer.writeln(
      'COMPRAS DE TARJETAS',
    );

    if (purchases.isEmpty) {
      buffer.writeln(
        'No hay compras de tarjetas registradas.',
      );
    } else {
      // Limitar información enviada a Pau.

      final recentPurchases =
          purchases.length > 50
              ? purchases.take(50)
              : purchases;

      for (final purchase
          in recentPurchases) {
        final cardName =
            _getCardName(
          creditCards,
          purchase.creditCardId,
        );

        buffer.write(
          '- ${purchase.purchaseDate} | '
          'Tarjeta: $cardName | '
          'Descripción: ${purchase.description} | '
          'Categoría: ${purchase.category} | '
          'Valor: ${_money(purchase.amount)} | '
          'Pagado: ${_money(purchase.paidAmount)} | '
          'Pendiente: ${_money(purchase.remainingAmount)}',
        );

        buffer.write(
          ' | Cuotas: ${purchase.installments}',
        );

        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  // ============================================================
  // BUSCAR NOMBRE DE CUENTA
  // ============================================================

  String _getAccountName(
    List<Account> accounts,
    int? accountId,
  ) {
    if (accountId == null) {
      return 'No especificada';
    }

    for (final account in accounts) {
      if (account.id == accountId) {
        return account.name;
      }
    }

    return 'Cuenta desconocida';
  }

  // ============================================================
  // BUSCAR NOMBRE DE TARJETA
  // ============================================================

  String _getCardName(
    List<CreditCard> cards,
    int cardId,
  ) {
    for (final card in cards) {
      if (card.id == cardId) {
        return card.name;
      }
    }

    return 'Tarjeta desconocida';
  }

  // ============================================================
  // FORMATEAR DINERO
  // ============================================================

  String _money(
    double value,
  ) {
    return '\$${value.toStringAsFixed(0)} COP';
  }
}