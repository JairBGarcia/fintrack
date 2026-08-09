import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../utils/currency_formatter.dart';

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

    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final result = await DatabaseHelper.instance.getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = result;
    });
  }

  double get totalMoney {
    return accounts.fold(
      0,
      (total, account) => total + account.balance,
    );
  }

  Future<void> openAddAccount() async {
    final result = await Navigator.push<Account>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAccountPage(),
      ),
    );

    if (result == null) {
      return;
    }

    await DatabaseHelper.instance.insertAccount(result);

    await loadAccounts();
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddAccount,
        icon: const Icon(Icons.add),
        label: const Text('Agregar cuenta'),
      ),

      body: RefreshIndicator(
        onRefresh: loadAccounts,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            const Text(
              'Resumen financiero',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // PATRIMONIO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Patrimonio total',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      CurrencyFormatter.format(totalMoney),

                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Dinero disponible en tus cuentas',

                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // DINERO Y DEUDAS
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Dinero',

                    value: CurrencyFormatter.format(
                      totalMoney,
                    ),

                    icon: Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: SummaryCard(
                    title: 'Deudas',

                    value: '\$0',

                    icon: Icons.credit_card,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // TITULO CUENTAS
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Mis cuentas',

                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  '${accounts.length}',

                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CUENTAS
            if (accounts.isEmpty)
              EmptyAccountsCard(
                onAddAccount: openAddAccount,
              )
            else
              ...accounts.map(
                (account) => AccountCard(
                  account: account,
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TARJETA DE CUENTA
// ============================================================

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({
    super.key,
    required this.account,
  });

  IconData getAccountIcon() {
    switch (account.type) {
      case 'Efectivo':
        return Icons.payments_outlined;

      case 'Cuenta de ahorros':
        return Icons.savings_outlined;

      case 'Cuenta corriente':
        return Icons.account_balance;

      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),

        leading: CircleAvatar(
          child: Icon(
            getAccountIcon(),
          ),
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
          CurrencyFormatter.format(
            account.balance,
          ),

          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TARJETAS DE RESUMEN
// ============================================================

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
            ),

            const SizedBox(height: 10),

            Text(
              title,

              style: const TextStyle(
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,

              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CUANDO NO HAY CUENTAS
// ============================================================

class EmptyAccountsCard extends StatelessWidget {
  final VoidCallback onAddAccount;

  const EmptyAccountsCard({
    super.key,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 50,
            ),

            const SizedBox(height: 12),

            const Text(
              'Todavía no tienes cuentas',

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Agrega Lulo, Bancolombia, efectivo, etc.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: onAddAccount,

              icon: const Icon(
                Icons.add,
              ),

              label: const Text(
                'Agregar cuenta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PANTALLA AGREGAR CUENTA
// ============================================================

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({
    super.key,
  });

  @override
  State<AddAccountPage> createState() =>
      _AddAccountPageState();
}

class _AddAccountPageState
    extends State<AddAccountPage> {

  final nameController =
      TextEditingController();

  final balanceController =
      TextEditingController();

  String selectedType =
      'Cuenta de ahorros';

  final List<String> accountTypes = [
    'Cuenta de ahorros',
    'Cuenta corriente',
    'Efectivo',
    'Otro',
  ];

  @override
  void dispose() {
    nameController.dispose();

    balanceController.dispose();

    super.dispose();
  }

  void saveAccount() {
    final name =
        nameController.text.trim();

    final balanceText =
        balanceController.text
            .trim()
            .replaceAll('.', '')
            .replaceAll(',', '.');

    final balance =
        double.tryParse(balanceText);

    if (name.isEmpty) {
      showError(
        'Escribe el nombre de la cuenta.',
      );

      return;
    }

    if (balance == null || balance < 0) {
      showError(
        'Escribe un saldo válido.',
      );

      return;
    }

    final account = Account(
      name: name,
      type: selectedType,
      balance: balance,
    );

    Navigator.pop(
      context,
      account,
    );
  }

  void showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar cuenta',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const Text(
            'Nueva cuenta',

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Registra dónde tienes tu dinero.',

            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          // NOMBRE
          TextField(
            controller: nameController,

            textCapitalization:
                TextCapitalization.words,

            decoration: const InputDecoration(
              labelText: 'Nombre',

              hintText: 'Ej: Lulo Bank',

              border: OutlineInputBorder(),

              prefixIcon: Icon(
                Icons.account_balance_wallet,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TIPO
          DropdownButtonFormField<String>(
            initialValue: selectedType,

            decoration:
                const InputDecoration(
              labelText: 'Tipo de cuenta',

              border: OutlineInputBorder(),

              prefixIcon: Icon(
                Icons.category_outlined,
              ),
            ),

            items: accountTypes.map(
              (type) {
                return DropdownMenuItem(
                  value: type,

                  child: Text(
                    type,
                  ),
                );
              },
            ).toList(),

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedType = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // SALDO
          TextField(
            controller:
                balanceController,

            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),

            decoration:
                const InputDecoration(
              labelText: 'Saldo actual',

              hintText: '800000',

              prefixText: '\$ ',

              border: OutlineInputBorder(),

              prefixIcon: Icon(
                Icons.attach_money,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // GUARDAR
          SizedBox(
            height: 52,

            child: FilledButton.icon(
              onPressed: saveAccount,

              icon: const Icon(
                Icons.save,
              ),

              label: const Text(
                'Guardar cuenta',

                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}