import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
      );
    }

    final number = int.parse(digitsOnly);

    final formatted = _formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }

  String _formatNumber(int number) {
    final text = number.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState
    extends State<AddTransactionPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Account> accounts = [];

  String type = 'gasto';
  String category = 'Alimentación';

  Account? selectedAccount;
  Account? destinationAccount;

  final categories = [
    'Alimentación',
    'Transporte',
    'Entretenimiento',
    'Compras',
    'Salud',
    'Hogar',
    'Salario',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final result =
        await DatabaseHelper.instance.getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = result;

      if (result.isNotEmpty) {
        selectedAccount = result.first;
      }
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void saveMovement() {
    final amount = double.tryParse(
      amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) {
      showError(
        'Ingresa un monto válido.',
      );
      return;
    }

    if (selectedAccount == null) {
      showError(
        'Selecciona una cuenta.',
      );
      return;
    }

    if (type == 'transferencia' &&
        destinationAccount == null) {
      showError(
        'Selecciona la cuenta destino.',
      );
      return;
    }

    if (type == 'transferencia' &&
        destinationAccount!.id ==
            selectedAccount!.id) {
      showError(
        'La cuenta origen y destino no pueden ser iguales.',
      );
      return;
    }

    final movement = TransactionModel(
      type: type,
      amount: amount,
      accountId: selectedAccount!.id,
      destinationAccountId:
          type == 'transferencia'
              ? destinationAccount!.id
              : null,
      category: type == 'transferencia'
          ? 'Transferencia'
          : category,
      description:
          descriptionController.text.trim(),
      date: DateTime.now(),
    );

    Navigator.pop(
      context,
      movement,
    );
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo movimiento',
        ),
      ),
      body: accounts.isEmpty
          ? const Center(
              child: Text(
                'Primero crea una cuenta.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Registrar movimiento',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TIPO
                // ==================================================

                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ingreso',
                      child: Text(
                        'Ingreso',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'gasto',
                      child: Text(
                        'Gasto',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'transferencia',
                      child: Text(
                        'Transferencia',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // MONTO
                // ==================================================

                TextField(
                  controller: amountController,
                  keyboardType:
                      TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration:
                      const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CUENTA
                // ==================================================

                DropdownButtonFormField<Account>(
                  initialValue: selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'Cuenta',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (account) =>
                            DropdownMenuItem(
                          value: account,
                          child: Text(
                            account.name,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAccount = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CUENTA DESTINO
                // ==================================================

                if (type == 'transferencia')
                  DropdownButtonFormField<Account>(
                    initialValue:
                        destinationAccount,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Cuenta destino',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: accounts
                        .map(
                          (account) =>
                              DropdownMenuItem(
                            value: account,
                            child: Text(
                              account.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        destinationAccount =
                            value;
                      });
                    },
                  ),

                if (type == 'transferencia')
                  const SizedBox(height: 18),

                // ==================================================
                // CATEGORÍA
                // ==================================================

                if (type != 'transferencia')
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration:
                        const InputDecoration(
                      labelText: 'Categoría',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: categories
                        .map(
                          (c) =>
                              DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        category = value!;
                      });
                    },
                  ),

                if (type != 'transferencia')
                  const SizedBox(height: 18),

                // ==================================================
                // DESCRIPCIÓN
                // ==================================================

                TextField(
                  controller:
                      descriptionController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Ej: Almuerzo con amigos',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // GUARDAR
                // ==================================================

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saveMovement,
                    icon: const Icon(
                      Icons.save,
                    ),
                    label: const Text(
                      'Guardar movimiento',
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