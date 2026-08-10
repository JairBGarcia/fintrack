import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/credit_card.dart';
import '../utils/currency_formatter.dart';

class AddCreditCardPage extends StatefulWidget {
  const AddCreditCardPage({
    super.key,
  });

  @override
  State<AddCreditCardPage> createState() =>
      _AddCreditCardPageState();
}

class _AddCreditCardPageState
    extends State<AddCreditCardPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final bankController = TextEditingController();
  final creditLimitController =
      TextEditingController();
  final cutoffDayController =
      TextEditingController();
  final paymentDueDayController =
      TextEditingController();
  final minimumPaymentController =
      TextEditingController();

  bool isSaving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    bankController.dispose();
    creditLimitController.dispose();
    cutoffDayController.dispose();
    paymentDueDayController.dispose();
    minimumPaymentController.dispose();

    super.dispose();
  }

  // ============================================================
  // CONVERTIR DINERO
  // ============================================================

  double parseMoney(String value) {
    return double.tryParse(
          value
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .replaceAll('\$', '')
              .trim(),
        ) ??
        0;
  }

  // ============================================================
  // FORMATEAR DINERO
  // ============================================================

  void formatMoneyField(
    TextEditingController controller,
  ) {
    final value = controller.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('\$', '');

    if (value.isEmpty) {
      return;
    }

    final number = int.tryParse(value);

    if (number == null) {
      return;
    }

    final formatted = formatCurrency(
      number.toDouble(),
    );

    final cleanValue =
        formatted.substring(1);

    controller.value =
        TextEditingValue(
      text: cleanValue,
      selection:
          TextSelection.collapsed(
        offset: cleanValue.length,
      ),
    );
  }

  // ============================================================
  // VALIDAR DÍA
  // ============================================================

  String? validateDay(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingresa el día';
    }

    final day =
        int.tryParse(value.trim());

    if (day == null) {
      return 'Ingresa un número válido';
    }

    if (day < 1 || day > 31) {
      return 'Debe estar entre 1 y 31';
    }

    return null;
  }

  // ============================================================
  // GUARDAR TARJETA
  // ============================================================

  Future<void> saveCreditCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final creditLimit =
        parseMoney(
      creditLimitController.text,
    );

    final minimumPayment =
        parseMoney(
      minimumPaymentController.text,
    );

    final cutoffDay =
        int.tryParse(
      cutoffDayController.text.trim(),
    );

    final paymentDueDay =
        int.tryParse(
      paymentDueDayController.text.trim(),
    );

    if (creditLimit <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'El cupo debe ser mayor que 0',
          ),
        ),
      );

      return;
    }

    if (minimumPayment < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'El valor no puede ser negativo',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final card = CreditCard(
        name: nameController.text.trim(),
        bank: bankController.text.trim(),
        creditLimit: creditLimit,
        usedAmount: 0,
        cutoffDay: cutoffDay,
        paymentDueDay: paymentDueDay,
        minimumPayment: minimumPayment,
      );

      await DatabaseHelper.instance
          .insertCreditCard(card);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Tarjeta agregada correctamente',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la tarjeta: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DECORACIÓN DE CAMPOS
  // ============================================================

  InputDecoration inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar tarjeta',
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
            // INFORMACIÓN
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(16),

              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.credit_card,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Text(
                      'Registra los datos de tu tarjeta para comenzar a controlar tu cupo, compras, fechas de corte y pagos.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // NOMBRE
            // ==================================================

            TextFormField(
              controller:
                  nameController,

              textCapitalization:
                  TextCapitalization.words,

              decoration:
                  inputDecoration(
                'Nombre de la tarjeta',
                hint:
                    'Ej: RappiCard',
                icon:
                    Icons.credit_card,
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingresa el nombre de la tarjeta';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // BANCO
            // ==================================================

            TextFormField(
              controller:
                  bankController,

              textCapitalization:
                  TextCapitalization.words,

              decoration:
                  inputDecoration(
                'Banco o entidad',
                hint:
                    'Ej: Rappi',
                icon:
                    Icons.account_balance,
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingresa el banco o entidad';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // CUPO
            // ==================================================

            TextFormField(
              controller:
                  creditLimitController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  inputDecoration(
                'Cupo total',
                hint:
                    'Ej: 6.800.000',
                icon:
                    Icons
                        .account_balance_wallet,
              ),

              onChanged: (_) {
                formatMoneyField(
                  creditLimitController,
                );
              },

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingresa el cupo total';
                }

                final amount =
                    parseMoney(value);

                if (amount <= 0) {
                  return 'El cupo debe ser mayor que 0';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // FECHAS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      TextFormField(
                    controller:
                        cutoffDayController,

                    keyboardType:
                        TextInputType.number,

                    decoration:
                        inputDecoration(
                      'Día de corte',
                      hint: 'Ej: 15',
                      icon:
                          Icons
                              .calendar_today,
                    ),

                    validator:
                        validateDay,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      TextFormField(
                    controller:
                        paymentDueDayController,

                    keyboardType:
                        TextInputType.number,

                    decoration:
                        inputDecoration(
                      'Día de pago',
                      hint: 'Ej: 30',
                      icon:
                          Icons
                              .event_available,
                    ),

                    validator:
                        validateDay,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PAGO MÍNIMO OPCIONAL
            // ==================================================

            TextFormField(
              controller:
                  minimumPaymentController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  inputDecoration(
                'Pago mínimo',
                hint:
                    'Opcional',
                icon:
                    Icons
                        .payments_outlined,
              ),

              onChanged: (_) {
                formatMoneyField(
                  minimumPaymentController,
                );
              },

              validator: (value) {
                // El campo es opcional.
                if (value == null ||
                    value.trim().isEmpty) {
                  return null;
                }

                final amount =
                    parseMoney(value);

                if (amount < 0) {
                  return 'El valor no puede ser negativo';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Este dato es opcional. Si no conoces el pago mínimo de tu tarjeta, puedes dejarlo vacío. Más adelante podremos registrarlo a partir de cada extracto.',

              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            // ==================================================
            // GUARDAR
            // ==================================================

            SizedBox(
              height: 54,

              child:
                  FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : saveCreditCard,

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
                        Icons
                            .save_outlined,
                      ),

                label: Text(
                  isSaving
                      ? 'Guardando...'
                      : 'Guardar tarjeta',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // CANCELAR
            // ==================================================

            SizedBox(
              height: 50,

              child: TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                        );
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