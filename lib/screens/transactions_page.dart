import 'package:flutter/material.dart';

import 'edit_transaction_page.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() =>
      _TransactionsPageState();
}

class _TransactionsPageState
    extends State<TransactionsPage> {
  List<TransactionModel> transactions = [];
  List<Account> accounts = [];

  String selectedType = 'Todos';
  String selectedAccount = 'Todas';
  String selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> loadData() async {
    final transactionResult =
        await DatabaseHelper.instance
            .getTransactions();

    final accountResult =
        await DatabaseHelper.instance
            .getAccounts();

    if (!mounted) return;

    setState(() {
      transactions = transactionResult;
      accounts = accountResult;
    });
  }

  // ============================================================
  // FILTROS
  // ============================================================

  List<TransactionModel>
      get filteredTransactions {
    return transactions.where(
      (transaction) {
        if (selectedType != 'Todos') {
          if (transaction.type !=
              selectedType.toLowerCase()) {
            return false;
          }
        }

        if (selectedAccount != 'Todas') {
          final account =
              accounts.where(
            (account) =>
                account.id ==
                transaction.accountId,
          );

          if (account.isEmpty) {
            return false;
          }

          if (account.first.name !=
              selectedAccount) {
            return false;
          }
        }

        if (selectedCategory != 'Todas') {
          if (transaction.category !=
              selectedCategory) {
            return false;
          }
        }

        return true;
      },
    ).toList();
  }

  // ============================================================
  // CATEGORÍAS
  // ============================================================

  List<String> get categories {
    final result = transactions
        .map(
          (transaction) =>
              transaction.category,
        )
        .where(
          (category) => category.isNotEmpty,
        )
        .toSet()
        .toList();

    result.sort();

    return [
      'Todas',
      ...result,
    ];
  }

  // ============================================================
  // CUENTA
  // ============================================================

  String getAccountName(
    int? accountId,
  ) {
    if (accountId == null) {
      return 'Sin cuenta';
    }

    for (final account in accounts) {
      if (account.id == accountId) {
        return account.name;
      }
    }

    return 'Cuenta desconocida';
  }

  // ============================================================
  // ICONOS
  // ============================================================

  IconData getIcon(String type) {
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

  // ============================================================
  // COLORES
  // ============================================================

  Color getColor(String type) {
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

  // ============================================================
  // MONTO
  // ============================================================

  String getAmountText(
    TransactionModel transaction,
  ) {
    switch (transaction.type) {
      case 'ingreso':
        return '+${formatCurrency(transaction.amount)}';

      case 'gasto':
        return '-${formatCurrency(transaction.amount)}';

      case 'transferencia':
        return formatCurrency(transaction.amount);

      default:
        return formatCurrency(transaction.amount);
    }
  }

  // ============================================================
  // TIPO
  // ============================================================

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

  // ============================================================
  // FECHA
  // ============================================================

  String formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  // ============================================================
  // RESUMEN
  // ============================================================

  double get totalIncome {
    return filteredTransactions
        .where(
          (transaction) =>
              transaction.type ==
              'ingreso',
        )
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  double get totalExpenses {
    return filteredTransactions
        .where(
          (transaction) =>
              transaction.type ==
              'gasto',
        )
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  double get balanceDifference {
    return totalIncome - totalExpenses;
  }

  // ============================================================
  // LIMPIAR FILTROS
  // ============================================================

  void clearFilters() {
    setState(() {
      selectedType = 'Todos';
      selectedAccount = 'Todas';
      selectedCategory = 'Todas';
    });
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  Future<void> deleteTransaction(
    TransactionModel transaction,
  ) async {
    if (transaction.id == null) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar movimiento',
          ),
          content: const Text(
            '¿Seguro que quieres eliminar este movimiento? '
            'El saldo de la cuenta también será revertido.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DatabaseHelper.instance
        .deleteTransaction(
      transaction.id!,
    );

    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Movimiento eliminado y saldo revertido.',
        ),
      ),
    );
  }

  // ============================================================
  // EDITAR
  // ============================================================

Future<void> editTransaction(
  TransactionModel transaction,
) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) {
        return EditTransactionPage(
          transaction: transaction,
        );
      },
    ),
  );

  if (result == true) {
    await loadData();
  }
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered =
        filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movimientos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: ListView(
          padding:
              const EdgeInsets.all(16),

          children: [
            const Text(
              'Tipo de movimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,

              child: Row(
                children: [
                  _FilterButton(
                    text: 'Todos',
                    selected:
                        selectedType ==
                            'Todos',
                    onPressed: () {
                      setState(() {
                        selectedType =
                            'Todos';
                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _FilterButton(
                    text: 'Ingresos',
                    selected:
                        selectedType ==
                            'Ingreso',
                    onPressed: () {
                      setState(() {
                        selectedType =
                            'Ingreso';
                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _FilterButton(
                    text: 'Gastos',
                    selected:
                        selectedType ==
                            'Gasto',
                    onPressed: () {
                      setState(() {
                        selectedType =
                            'Gasto';
                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _FilterButton(
                    text:
                        'Transferencias',
                    selected:
                        selectedType ==
                            'Transferencia',
                    onPressed: () {
                      setState(() {
                        selectedType =
                            'Transferencia';
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedAccount,

              decoration:
                  const InputDecoration(
                labelText: 'Cuenta',
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.account_balance,
                ),
              ),

              items: [
                const DropdownMenuItem(
                  value: 'Todas',
                  child: Text(
                    'Todas',
                  ),
                ),

                ...accounts.map(
                  (account) {
                    return DropdownMenuItem(
                      value: account.name,
                      child: Text(
                        account.name,
                      ),
                    );
                  },
                ),
              ],

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedAccount =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedCategory,

              decoration:
                  const InputDecoration(
                labelText:
                    'Categoría',
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.category,
                ),
              ),

              items: categories.map(
                (category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                    ),
                  );
                },
              ).toList(),

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedCategory =
                      value;
                });
              },
            ),

            if (selectedType !=
                    'Todos' ||
                selectedAccount !=
                    'Todas' ||
                selectedCategory !=
                    'Todas')
              Align(
                alignment:
                    Alignment.centerRight,
                child:
                    TextButton.icon(
                  onPressed:
                      clearFilters,
                  icon: const Icon(
                    Icons.clear,
                  ),
                  label: const Text(
                    'Limpiar filtros',
                  ),
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Resumen',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      _SummaryCard(
                    title: 'Ingresos',
                    value:
                        formatCurrency(
                      totalIncome,
                    ),
                    icon: Icons
                        .arrow_downward,
                    color:
                        Colors.green,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      _SummaryCard(
                    title: 'Gastos',
                    value:
                        formatCurrency(
                      totalExpenses,
                    ),
                    icon:
                        Icons.arrow_upward,
                    color:
                        Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  balanceDifference >=
                          0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color:
                      balanceDifference >=
                              0
                          ? Colors.green
                          : Colors.red,
                ),

                title: const Text(
                  'Balance de movimientos',
                ),

                trailing: Text(
                  formatCurrency(
                    balanceDifference,
                  ),
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        balanceDifference >=
                                0
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  '${filtered.length} movimiento${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (filtered.isEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),

                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 45,
                        color: Colors
                            .grey.shade500,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'No hay movimientos con estos filtros.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            ...filtered.map(
              (transaction) {
                return _TransactionCard(
                  transaction:
                      transaction,
                  accountName:
                      getAccountName(
                    transaction.accountId,
                  ),
                  icon: getIcon(
                    transaction.type,
                  ),
                  color: getColor(
                    transaction.type,
                  ),
                  amountText:
                      getAmountText(
                    transaction,
                  ),
                  typeText:
                      getTypeText(
                    transaction.type,
                  ),
                  dateText:
                      formatDate(
                    transaction.date,
                  ),
                  onEdit: () =>
                      editTransaction(
                    transaction,
                  ),
                  onDelete: () =>
                      deleteTransaction(
                    transaction,
                  ),
                );
              },
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

// =================================================================
// BOTÓN FILTRO
// =================================================================

class _FilterButton
    extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) {
        onPressed();
      },
    );
  }
}

// =================================================================
// TARJETA RESUMEN
// =================================================================

class _SummaryCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              color: color,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TARJETA MOVIMIENTO
// =================================================================

class _TransactionCard
    extends StatelessWidget {
  final TransactionModel transaction;
  final String accountName;
  final IconData icon;
  final Color color;
  final String amountText;
  final String typeText;
  final String dateText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.accountName,
    required this.icon,
    required this.color,
    required this.amountText,
    required this.typeText,
    required this.dateText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),

        leading: CircleAvatar(
          child: Icon(
            icon,
            color: color,
          ),
        ),

        title: Text(
          transaction.description
                  .isEmpty
              ? transaction.category
              : transaction.description,

          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 16,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(
              height: 4,
            ),

            Text(
              '$typeText • ${transaction.category}',
            ),

            Text(
              accountName,
            ),

            Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors
                    .grey.shade600,
              ),
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Text(
              amountText,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  onEdit();
                }

                if (value == 'eliminar') {
                  onDelete();
                }
              },

              itemBuilder:
                  (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        'Editar',
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        'Eliminar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}