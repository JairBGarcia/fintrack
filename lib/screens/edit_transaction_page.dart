import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionPage({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionPage> createState() =>
      _EditTransactionPageState();
}

class _EditTransactionPageState
    extends State<EditTransactionPage> {
  late TextEditingController amountController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;

  List<Account> accounts = [];

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    amountController = TextEditingController(
      text: widget.transaction.amount
          .toStringAsFixed(0),
    );

    categoryController = TextEditingController(
      text: widget.transaction.category,
    );

    descriptionController = TextEditingController(
      text: widget.transaction.description,
    );

    loadAccounts();
  }

  @override
  void dispose() {
    amountController.dispose();
    categoryController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  Future<void> loadAccounts() async {
    final result =
        await DatabaseHelper.instance
            .getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = result;
    });
  }

  Future<void> saveTransaction() async {
    if (isSaving) return;

    final cleanAmount = amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    final amount =
        double.tryParse(cleanAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un monto válido.',
          ),
        ),
      );

      return;
    }

    final category =
        categoryController.text.trim();

    if (category.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa una categoría.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    final updatedTransaction =
        TransactionModel(
      id: widget.transaction.id,
      type: widget.transaction.type,
      amount: amount,
      accountId:
          widget.transaction.accountId,
      destinationAccountId:
          widget.transaction
              .destinationAccountId,
      category: category,
      description:
          descriptionController.text.trim(),
      date: widget.transaction.date,
    );

    try {
      await DatabaseHelper.instance
          .updateTransaction(
        updatedTransaction,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar: $e',
          ),
        ),
      );
    }
  }

  String getTypeText(String type) {
    switch (type) {
      case 'ingreso':
        return 'Ingreso';

      case 'gasto':
        return 'Gasto';

      case 'transferencia':
        return 'Transferencia';

      default:
        return 'Movimiento';
    }
  }

  IconData getTypeIcon(String type) {
    switch (type) {
      case 'ingreso':
        return Icons.arrow_downward;

      case 'gasto':
        return Icons.arrow_upward;

      case 'transferencia':
        return Icons.swap_horiz;

      default:
        return Icons.attach_money;
    }
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'ingreso':
        return Colors.green;

      case 'gasto':
        return Colors.red;

      case 'transferencia':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor =
        getTypeColor(
      widget.transaction.type,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar movimiento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // TIPO DE MOVIMIENTO
            // ==================================================

            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withValues(
  alpha: 0.15,
),
                  child: Icon(
                    getTypeIcon(
                      widget.transaction.type,
                    ),
                    color: typeColor,
                  ),
                ),

                title: Text(
                  getTypeText(
                    widget.transaction.type,
                  ),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'El tipo de movimiento no se puede cambiar aquí.',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // MONTO
            // ==================================================

            TextField(
              controller:
                  amountController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.attach_money,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CATEGORÍA
            // ==================================================

            TextField(
              controller:
                  categoryController,

              decoration:
                  const InputDecoration(
                labelText: 'Categoría',
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.category,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DESCRIPCIÓN
            // ==================================================

            TextField(
              controller:
                  descriptionController,

              maxLines: 3,

              decoration:
                  const InputDecoration(
                labelText:
                    'Descripción',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.description,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // BOTÓN GUARDAR
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,

              child: FilledButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : saveTransaction,

                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),

                label: Text(
                  isSaving
                      ? 'Guardando...'
                      : 'Guardar cambios',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.of(
                          context,
                        ).pop();
                      },

                child: const Text(
                  'Cancelar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}