import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../utils/currency_formatter.dart';
import 'add_transaction_page.dart';
import 'transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = await DatabaseHelper.instance.getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = result;
    });
  }

  double get totalMoney {
    return accounts.fold(
      0,
      (sum, account) => sum + account.balance,
    );
  }

  Future<void> openAddTransaction() async {
    final transaction = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );

    if (transaction != null) {
      await DatabaseHelper.instance.insertTransaction(
        transaction,
      );

      await loadData();
    }
  }

  Future<void> openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsPage(),
      ),
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FinTrack',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            // =====================================================
            // RESUMEN
            // =====================================================

            const Text(
              'Resumen financiero',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // PATRIMONIO TOTAL
            // =====================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Patrimonio total',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      formatCurrency(totalMoney),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =====================================================
            // MIS CUENTAS
            // =====================================================

            const Text(
              'Mis cuentas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

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
                    leading: const Icon(
                      Icons.account_balance_wallet,
                    ),

                    title: Text(
                      account.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      account.type,
                    ),

                    trailing: Text(
                      formatCurrency(
                        account.balance,
                      ),

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // =====================================================
            // AGREGAR MOVIMIENTO
            // =====================================================

            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                onPressed: openAddTransaction,

                icon: const Icon(
                  Icons.add,
                ),

                label: const Text(
                  'Agregar movimiento',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // VER MOVIMIENTOS
            // =====================================================

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: openTransactions,

                icon: const Icon(
                  Icons.history,
                ),

                label: const Text(
                  'Ver movimientos',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // ACTUALIZAR
            // =====================================================

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: loadData,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'Actualizar',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}