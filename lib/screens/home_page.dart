import 'package:flutter/material.dart';

import 'pau_page.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/credit_card.dart';
import '../utils/currency_formatter.dart';
import 'add_transaction_page.dart';
import 'transactions_page.dart';
import 'credit_cards_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  List<Account> accounts = [];
  List<CreditCard> creditCards = [];

  @override
  void initState() {
    super.initState();

    loadData();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> loadData() async {
    final accountsResult =
        await DatabaseHelper.instance
            .getAccounts();

    final cardsResult =
        await DatabaseHelper.instance
            .getCreditCards();

    if (!mounted) return;

    setState(() {
      accounts = accountsResult;
      creditCards = cardsResult;
    });
  }

  // ============================================================
  // PATRIMONIO TOTAL
  // ============================================================

  double get totalMoney {
    return accounts.fold(
      0,
      (sum, account) =>
          sum + account.balance,
    );
  }

  // ============================================================
  // AGREGAR MOVIMIENTO
  // ============================================================

  Future<void> openAddTransaction() async {
    final transaction =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddTransactionPage(),
      ),
    );

    if (transaction != null) {
      await DatabaseHelper.instance
          .insertTransaction(
        transaction,
      );

      await loadData();
    }
  }

  // ============================================================
  // VER MOVIMIENTOS
  // ============================================================

  Future<void> openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const TransactionsPage(),
      ),
    );

    await loadData();
  }

  // ============================================================
  // VER TARJETAS
  // ============================================================

  Future<void> openCreditCards() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CreditCardsPage(),
      ),
    );

    await loadData();
  }

  // ============================================================
  // COLOR SEGÚN UTILIZACIÓN
  // ============================================================

  Color getUsageColor(
    double percentage,
  ) {
    if (percentage >= 80) {
      return Colors.red;
    }

    if (percentage >= 50) {
      return Colors.orange;
    }

    return Colors.green;
  }

  // ============================================================
  // TARJETA RESUMIDA
  // ============================================================

  Widget buildCreditCardSummary(
    CreditCard card,
  ) {
    final usage =
        (card.usagePercentage / 100)
            .clamp(0.0, 1.0);

    final usageColor =
        getUsageColor(
      card.usagePercentage,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),

        onTap: openCreditCards,

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // NOMBRE
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primaryContainer,

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: Icon(
                      Icons.credit_card,
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          card.name,

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          card.bank,

                          style: TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ------------------------------------------------
              // CUPOS
              // ------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: _buildCardAmount(
                      'Cupo total',
                      card.creditLimit,
                    ),
                  ),

                  Expanded(
                    child: _buildCardAmount(
                      'Utilizado',
                      card.usedAmount,
                    ),
                  ),

                  Expanded(
                    child: _buildCardAmount(
                      'Disponible',
                      card.availableCredit,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              // ------------------------------------------------
              // BARRA
              // ------------------------------------------------

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),

                child:
                    LinearProgressIndicator(
                  value: usage,
                  minHeight: 7,

                  backgroundColor:
                      Theme.of(
                    context,
                  )
                      .colorScheme
                      .surfaceContainerHighest,

                  color: usageColor,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Row(
                children: [
                  Text(
                    '${card.usagePercentage.toStringAsFixed(1)}% utilizado',

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: usageColor,
                    ),
                  ),

                  const Spacer(),

                  if (card.cutoffDay != null)
                    Text(
                      'Corte: día ${card.cutoffDay}',

                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VALOR DE TARJETA
  // ============================================================

  Widget _buildCardAmount(
    String title,
    double value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            )
                .colorScheme
                .onSurfaceVariant,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          formatCurrency(value),

          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FinTrack',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            // ==================================================
            // RESUMEN
            // ==================================================

            const Text(
              'Resumen financiero',

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PauPage(),
        ),
      );
    },
    icon: const Icon(
      Icons.auto_awesome,
    ),
    label: const Text(
      'Hablar con Pau',
    ),
  ),
),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // PATRIMONIO TOTAL
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Patrimonio total',

                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      formatCurrency(
                        totalMoney,
                      ),

                      style:
                          const TextStyle(
                        fontSize: 32,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // MIS CUENTAS
            // ==================================================

            const Text(
              'Mis cuentas',

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (accounts.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.account_balance,
                  ),

                  title: Text(
                    'Todavía no tienes cuentas',
                  ),

                  subtitle: Text(
                    'Agrega Lulo, Bancolombia, efectivo, etc.',
                  ),
                ),
              )
            else
              ...accounts.map(
                (account) => Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons
                          .account_balance_wallet,
                    ),

                    title: Text(
                      account.name,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      account.type,
                    ),

                    trailing: Text(
                      formatCurrency(
                        account.balance,
                      ),

                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // ==================================================
            // MIS TARJETAS
            // ==================================================

            const SizedBox(
              height: 28,
            ),

            const Text(
              'Mis tarjetas',

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (creditCards.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.credit_card,
                  ),

                  title: const Text(
                    'Todavía no tienes tarjetas',
                  ),

                  subtitle: const Text(
                    'Agrega una tarjeta de crédito para comenzar a controlarla.',
                  ),

                  trailing: IconButton(
                    onPressed:
                        openCreditCards,

                    icon: const Icon(
                      Icons.add,
                    ),
                  ),
                ),
              )
            else ...[
              ...creditCards.map(
                buildCreditCardSummary,
              ),

              const SizedBox(
                height: 2,
              ),

              SizedBox(
                width: double.infinity,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      openCreditCards,

                  icon: const Icon(
                    Icons.credit_card,
                  ),

                  label: const Text(
                    'Ver todas las tarjetas',
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // AGREGAR MOVIMIENTO
            // ==================================================

            SizedBox(
              width: double.infinity,

              child:
                  FilledButton.icon(
                onPressed:
                    openAddTransaction,

                icon: const Icon(
                  Icons.add,
                ),

                label: const Text(
                  'Agregar movimiento',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // VER MOVIMIENTOS
            // ==================================================

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    openTransactions,

                icon: const Icon(
                  Icons.history,
                ),

                label: const Text(
                  'Ver movimientos',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // ACTUALIZAR
            // ==================================================

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed: loadData,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'Actualizar',
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}