import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() =>
      _AddAccountPageState();
}

class _AddAccountPageState
    extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _balanceController =
      TextEditingController();

  String _selectedType =
      'Cuenta de ahorros';

  final List<String> _accountTypes = [
    'Cuenta de ahorros',
    'Cuenta corriente',
    'Efectivo',
    'Billetera digital',
    'Otro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();

    super.dispose();
  }

  // ============================================================
  // CONVERTIR SALDO
  // ============================================================

  double _parseBalance(String value) {
    var clean = value.trim();

    clean = clean.replaceAll('.', '');
    clean = clean.replaceAll(',', '.');

    return double.tryParse(clean) ?? 0;
  }

  // ============================================================
  // GUARDAR CUENTA
  // ============================================================

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final balance =
        _parseBalance(
      _balanceController.text,
    );

    final account = Account(
      name: _nameController.text.trim(),
      type: _selectedType,
      balance: balance,
    );

    try {
      await DatabaseHelper.instance
          .insertAccount(account);

      if (!mounted) return;

      Navigator.of(context).pop(account);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la cuenta: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar cuenta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            // ==================================================
            // ICONO
            // ==================================================

            Center(
              child: Container(
                width: 72,
                height: 72,

                decoration:
                    BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Icon(
                  Icons.account_balance_wallet,
                  size: 36,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Nueva cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Agrega una cuenta para comenzar a controlar tu dinero.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // NOMBRE
            // ==================================================

            TextFormField(
              controller:
                  _nameController,

              textCapitalization:
                  TextCapitalization.words,

              decoration:
                  const InputDecoration(
                labelText: 'Nombre',
                hintText:
                    'Ej: Bancolombia',
                prefixIcon:
                    Icon(Icons.account_balance),
                border:
                    OutlineInputBorder(),
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingresa el nombre de la cuenta.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // TIPO
            // ==================================================

            DropdownButtonFormField<String>(
              initialValue:
                  _selectedType,

              decoration:
                  const InputDecoration(
                labelText: 'Tipo de cuenta',
                prefixIcon:
                    Icon(Icons.category_outlined),
                border:
                    OutlineInputBorder(),
              ),

              items:
                  _accountTypes.map(
                (type) {
                  return DropdownMenuItem<
                      String>(
                    value: type,
                    child: Text(type),
                  );
                },
              ).toList(),

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedType = value;
                });
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // SALDO
            // ==================================================

            TextFormField(
              controller:
                  _balanceController,

              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration:
                  const InputDecoration(
                labelText:
                    'Saldo inicial',
                hintText:
                    'Ej: 500.000',
                prefixText:
                    '\$ ',
                prefixIcon:
                    Icon(Icons.payments_outlined),
                border:
                    OutlineInputBorder(),
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingresa el saldo inicial.';
                }

                final amount =
                    _parseBalance(value);

                if (amount < 0) {
                  return 'El saldo no puede ser negativo.';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // GUARDAR
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                onPressed:
                    _saveAccount,

                icon: const Icon(
                  Icons.check,
                ),

                label: const Text(
                  'Crear cuenta',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}