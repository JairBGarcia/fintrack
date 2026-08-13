import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/credit_card.dart';
import '../models/credit_card_purchase.dart';
import '../utils/currency_formatter.dart';

class CreditCardDetailPage extends StatefulWidget {
  final CreditCard creditCard;

  const CreditCardDetailPage({
    super.key,
    required this.creditCard,
  });

  @override
  State<CreditCardDetailPage> createState() =>
      _CreditCardDetailPageState();
}

class _CreditCardDetailPageState
    extends State<CreditCardDetailPage> {
  List<CreditCardPurchase> _purchases = [];
  List<Account> _accounts = [];

  bool _isLoading = true;

  late CreditCard _creditCard;

  @override
  void initState() {
    super.initState();

    _creditCard = widget.creditCard;

    _loadData();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_creditCard.id == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final card =
          await DatabaseHelper.instance.getCreditCardById(
        _creditCard.id!,
      );

      final purchases =
          await DatabaseHelper.instance.getPurchasesByCreditCard(
        _creditCard.id!,
      );

      final accounts =
          await DatabaseHelper.instance.getAccounts();

      if (!mounted) return;

      setState(() {
        if (card != null) {
          _creditCard = card;
        }

        _purchases = purchases;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar los datos: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // COLOR DE UTILIZACIÓN
  // ============================================================

  Color _getUsageColor(double percentage) {
    if (percentage >= 80) {
      return Colors.red;
    }

    if (percentage >= 50) {
      return Colors.orange;
    }

    return Colors.green;
  }

  // ============================================================
  // FORMATEAR FECHA
  // ============================================================

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // PARSEAR DINERO
  // ============================================================

  double _parseAmount(String value) {
    var clean = value.trim();

    clean = clean.replaceAll('.', '');
    clean = clean.replaceAll(',', '.');

    return double.tryParse(clean) ?? 0;
  }

  // ============================================================
  // REGISTRAR PAGO
  // ============================================================

  Future<void> _registerPayment(
    CreditCardPurchase purchase,
  ) async {
    if (purchase.id == null) {
      return;
    }

    if (purchase.isPaid) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta compra ya está pagada.',
          ),
        ),
      );

      return;
    }

    if (_accounts.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes cuentas disponibles para realizar el pago.',
          ),
        ),
      );

      return;
    }

    final payment =
        await _showPaymentDialog(purchase);

    if (!mounted || payment == null) {
      return;
    }

    try {
      final result =
          await DatabaseHelper.instance
              .registerCreditCardPayment(
        purchaseId: purchase.id!,
        paymentAmount: payment.amount,
        accountId: payment.accountId,
      );

      if (!mounted) return;

      if (result == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo registrar el pago. Verifica el saldo de la cuenta.',
            ),
          ),
        );

        return;
      }

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pago de ${formatCurrency(payment.amount)} registrado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo registrar el pago: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DIÁLOGO DE PAGO
  // ============================================================

  Future<_PaymentResult?> _showPaymentDialog(
    CreditCardPurchase purchase,
  ) async {
    return showDialog<_PaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PaymentDialog(
          purchase: purchase,
          accounts: _accounts,
          parseAmount: _parseAmount,
        );
      },
    );
  }

  // ============================================================
  // RESUMEN DE TARJETA
  // ============================================================

  Widget _buildCardSummary() {
    final usage =
        (_creditCard.usagePercentage / 100)
            .clamp(0.0, 1.0);

    final usageColor =
        _getUsageColor(
      _creditCard.usagePercentage,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _creditCard.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _creditCard.bank,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Cupo total',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              formatCurrency(
                _creditCard.creditLimit,
              ),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildMoneyInfo(
                    title: 'Utilizado',
                    value: formatCurrency(
                      _creditCard.usedAmount,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildMoneyInfo(
                    title: 'Disponible',
                    value: formatCurrency(
                      _creditCard.availableCredit,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: usage,
                minHeight: 9,
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                color: usageColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_creditCard.usagePercentage.toStringAsFixed(1)}% utilizado',
              style: TextStyle(
                color: usageColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.calendar_today,
                    title: 'Fecha de corte',
                    value:
                        _creditCard.cutoffDay != null
                            ? 'Día ${_creditCard.cutoffDay}'
                            : 'No definida',
                  ),
                ),
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.event_available,
                    title: 'Fecha de pago',
                    value:
                        _creditCard.paymentDueDay != null
                            ? 'Día ${_creditCard.paymentDueDay}'
                            : 'No definida',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Pago mínimo',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),

                  Text(
                    _creditCard.minimumPayment <= 0
                        ? 'No definido'
                        : formatCurrency(
                            _creditCard.minimumPayment,
                          ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN DE DINERO
  // ============================================================

  Widget _buildMoneyInfo({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFORMACIÓN DE FECHA
  // ============================================================

  Widget _buildDateInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TARJETA DE COMPRA
  // ============================================================

  Widget _buildPurchaseCard(
    CreditCardPurchase purchase,
  ) {
    final remaining =
        purchase.remainingAmount;

    final paidPercentage =
        (purchase.paidPercentage / 100)
            .clamp(0.0, 1.0);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(
                      purchase.category,
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.description,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.category,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  formatCurrency(
                    purchase.amount,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildPurchaseInfo(
                    title: 'Fecha',
                    value: _formatDate(
                      purchase.purchaseDate,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPurchaseInfo(
                    title: 'Cuotas',
                    value:
                        purchase.installments == 1
                            ? '1 cuota'
                            : '${purchase.installments} cuotas',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildPurchaseInfo(
                    title: 'Cuota base',
                    value: formatCurrency(
                      purchase.installmentAmount,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPurchaseInfo(
                    title: 'Tasa E.A.',
                    value:
                        '${purchase.annualEffectiveRate.toStringAsFixed(2)}%',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  purchase.isPaid
                      ? 'Pagada'
                      : 'Saldo pendiente',
                  style: TextStyle(
                    color: purchase.isPaid
                        ? Colors.green
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                Text(
                  purchase.isPaid
                      ? '✓'
                      : formatCurrency(
                          remaining,
                        ),
                  style: TextStyle(
                    color: purchase.isPaid
                        ? Colors.green
                        : null,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: paidPercentage,
                minHeight: 7,
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                color: purchase.isPaid
                    ? Colors.green
                    : Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${purchase.paidPercentage.toStringAsFixed(1)}% pagado',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            if (!purchase.isPaid) ...[
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    _registerPayment(
                      purchase,
                    );
                  },
                  icon: const Icon(
                    Icons.payments_outlined,
                  ),
                  label: const Text(
                    'Registrar pago',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMACIÓN DE COMPRA
  // ============================================================

  Widget _buildPurchaseInfo({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ICONO DE CATEGORÍA
  // ============================================================

  IconData _getCategoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Alimentación':
        return Icons.restaurant;

      case 'Transporte':
        return Icons.directions_car;

      case 'Hogar':
        return Icons.home;

      case 'Entretenimiento':
        return Icons.movie;

      case 'Tecnología':
        return Icons.devices;

      case 'Salud':
        return Icons.health_and_safety;

      case 'Ropa':
        return Icons.checkroom;

      case 'Educación':
        return Icons.school;

      case 'Viajes':
        return Icons.flight;

      case 'Suscripciones':
        return Icons.subscriptions;

      default:
        return Icons.shopping_bag;
    }
  }

  // ============================================================
  // RESUMEN DE COMPRAS
  // ============================================================

  Widget _buildPurchasesSummary() {
    if (_purchases.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalPurchases = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (final purchase in _purchases) {
      totalPurchases += purchase.amount;
      totalPaid += purchase.paidAmount;
      totalPending += purchase.remainingAmount;
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de compras',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Compras',
                    formatCurrency(
                      totalPurchases,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pagado',
                    formatCurrency(
                      totalPaid,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pendiente',
                    formatCurrency(
                      totalPending,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM DE RESUMEN
  // ============================================================

  Widget _buildSummaryItem(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _creditCard.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  _buildCardSummary(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Compras',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        '${_purchases.length}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildPurchasesSummary(),

                  if (_purchases.isNotEmpty)
                    const SizedBox(height: 12),

                  if (_purchases.isEmpty)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          28,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .shopping_cart_outlined,
                              size: 56,
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .primary,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            const Text(
                              'No hay compras',
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              'Todavía no has registrado compras con esta tarjeta.',
                              textAlign:
                                  TextAlign.center,
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
                    )
                  else
                    ..._purchases.map(
                      _buildPurchaseCard,
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

// ================================================================
// RESULTADO DEL PAGO
// ================================================================

class _PaymentResult {
  final double amount;
  final int accountId;

  const _PaymentResult({
    required this.amount,
    required this.accountId,
  });
}

// ================================================================
// DIÁLOGO DE PAGO
// ================================================================

class _PaymentDialog extends StatefulWidget {
  final CreditCardPurchase purchase;
  final List<Account> accounts;
  final double Function(String) parseAmount;

  const _PaymentDialog({
    required this.purchase,
    required this.accounts,
    required this.parseAmount,
  });

  @override
  State<_PaymentDialog> createState() =>
      _PaymentDialogState();
}

class _PaymentDialogState
    extends State<_PaymentDialog> {
  late final TextEditingController _controller;

  Account? _selectedAccount;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController();

    if (widget.accounts.isNotEmpty) {
      _selectedAccount =
          widget.accounts.first;
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _submit() {
    final amount =
        widget.parseAmount(
      _controller.text,
    );

    if (amount <= 0) {
      setState(() {
        _errorText =
            'Ingresa un valor válido.';
      });

      return;
    }

    if (amount >
        widget.purchase.remainingAmount) {
      setState(() {
        _errorText =
            'No puedes pagar más del saldo pendiente.';
      });

      return;
    }

    if (_selectedAccount == null ||
        _selectedAccount!.id == null) {
      setState(() {
        _errorText =
            'Selecciona una cuenta.';
      });

      return;
    }

    if (_selectedAccount!.balance <
        amount) {
      setState(() {
        _errorText =
            'La cuenta seleccionada no tiene saldo suficiente.';
      });

      return;
    }

    Navigator.of(context).pop(
      _PaymentResult(
        amount: amount,
        accountId:
            _selectedAccount!.id!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Registrar pago',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.purchase.description,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Saldo pendiente: ${formatCurrency(widget.purchase.remainingAmount)}',
            ),

            const SizedBox(height: 20),

            const Text(
              '¿De qué cuenta sale el dinero?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<Account>(
              initialValue:
                  _selectedAccount,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Cuenta de pago',
                prefixIcon:
                    Icon(Icons.account_balance),
                border:
                    OutlineInputBorder(),
              ),
              items:
                  widget.accounts.map(
                (account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Text(
                      '${account.name} — ${formatCurrency(account.balance)}',
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: (account) {
                if (account == null) {
                  return;
                }

                setState(() {
                  _selectedAccount =
                      account;
                  _errorText = null;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    'Valor del pago',
                hintText:
                    'Ej: 300.000',
                prefixText:
                    '\$ ',
                border:
                    const OutlineInputBorder(),
                errorText:
                    _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) {
                _submit();
              },
            ),

            const SizedBox(height: 12),

            if (_selectedAccount != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Saldo disponible',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),

                    Text(
                      formatCurrency(
                        _selectedAccount!
                            .balance,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancelar',
          ),
        ),

        FilledButton(
          onPressed: _submit,
          child: const Text(
            'Registrar',
          ),
        ),
      ],
    );
  }
}