import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/credit_card.dart';
import '../models/credit_card_purchase.dart';
import '../utils/currency_formatter.dart';

class AddCreditCardPurchasePage extends StatefulWidget {
  final CreditCard? creditCard;

  const AddCreditCardPurchasePage({
    super.key,
    this.creditCard,
  });

  @override
  State<AddCreditCardPurchasePage> createState() =>
      _AddCreditCardPurchasePageState();
}

class _AddCreditCardPurchasePageState
    extends State<AddCreditCardPurchasePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _rateController =
      TextEditingController();

  List<CreditCard> _cards = [];

  CreditCard? _selectedCard;

  String _selectedCategory = 'Otros';

  DateTime _purchaseDate = DateTime.now();

  int _installments = 1;

  bool _isSaving = false;
  bool _isLoadingCards = true;

  final List<String> _categories = [
    'Alimentación',
    'Transporte',
    'Hogar',
    'Entretenimiento',
    'Tecnología',
    'Salud',
    'Ropa',
    'Educación',
    'Viajes',
    'Suscripciones',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();

    super.dispose();
  }

  // ============================================================
  // CARGAR TARJETAS
  // ============================================================

  Future<void> _loadCards() async {
    if (mounted) {
      setState(() {
        _isLoadingCards = true;
      });
    }

    try {
      final cards =
          await DatabaseHelper.instance.getCreditCards();

      if (!mounted) return;

      CreditCard? selected;

      if (cards.isNotEmpty) {
        if (widget.creditCard != null) {
          for (final card in cards) {
            if (card.id == widget.creditCard!.id) {
              selected = card;
              break;
            }
          }
        }

        selected ??= cards.first;
      }

      setState(() {
        _cards = cards;
        _selectedCard = selected;
        _isLoadingCards = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCards = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las tarjetas: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // RECARGAR TARJETA SELECCIONADA
  // ============================================================

  Future<CreditCard?> _refreshSelectedCard() async {
    if (_selectedCard?.id == null) {
      return null;
    }

    final updatedCard =
        await DatabaseHelper.instance.getCreditCardById(
      _selectedCard!.id!,
    );

    if (updatedCard == null) {
      return null;
    }

    if (!mounted) {
      return updatedCard;
    }

    setState(() {
      _selectedCard = updatedCard;

      for (int i = 0; i < _cards.length; i++) {
        if (_cards[i].id == updatedCard.id) {
          _cards[i] = updatedCard;
          break;
        }
      }
    });

    return updatedCard;
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
  // CONVERTIR VALOR
  // ============================================================

  double _parseAmount(String value) {
    String clean = value.trim();

    clean = clean.replaceAll('.', '');
    clean = clean.replaceAll(',', '.');

    return double.tryParse(clean) ?? 0;
  }

  // ============================================================
  // SELECCIONAR FECHA
  // ============================================================

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _purchaseDate = selected;
    });
  }

  // ============================================================
  // GUARDAR COMPRA
  // ============================================================

  Future<void> _savePurchase() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCard == null ||
        _selectedCard!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una tarjeta válida.',
          ),
        ),
      );

      return;
    }

    final amount = _parseAmount(
      _amountController.text,
    );

    final rate =
        double.tryParse(
              _rateController.text
                  .trim()
                  .replaceAll(',', '.'),
            ) ??
            0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un valor válido.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // OBTENER TARJETA ACTUALIZADA
    // ==========================================================

    CreditCard? currentCard;

    try {
      currentCard = await _refreshSelectedCard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la información de la tarjeta: $e',
          ),
        ),
      );

      return;
    }

    if (currentCard == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La tarjeta seleccionada ya no existe.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // COMPROBAR CUPO ACTUAL
    // ==========================================================

    if (amount > currentCard.availableCredit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La compra supera el cupo disponible de '
            '${formatCurrency(
              currentCard.availableCredit,
            )}.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // CONFIRMAR GUARDADO
    // ==========================================================

    setState(() {
      _isSaving = true;
    });

    try {
      final purchase = CreditCardPurchase(
        creditCardId: currentCard.id!,
        description:
            _descriptionController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        purchaseDate: _purchaseDate,
        installments: _installments,
        annualEffectiveRate: rate,
        paidAmount: 0,
      );

      await DatabaseHelper.instance
          .insertCreditCardPurchase(
        purchase,
      );

      // ========================================================
      // RECARGAR TARJETA DESPUÉS DE LA COMPRA
      // ========================================================

      final updatedCard =
          await DatabaseHelper.instance.getCreditCardById(
        currentCard.id!,
      );

      if (!mounted) return;

      if (updatedCard != null) {
        setState(() {
          _selectedCard = updatedCard;

          for (int i = 0; i < _cards.length; i++) {
            if (_cards[i].id == updatedCard.id) {
              _cards[i] = updatedCard;
              break;
            }
          }
        });
      }

      // ========================================================
      // REGRESAR A LA PANTALLA ANTERIOR
      // ========================================================

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la compra: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDAR VALOR
  // ============================================================

  String? _validateAmount(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingresa el valor de la compra';
    }

    final amount =
        _parseAmount(value);

    if (amount <= 0) {
      return 'Ingresa un valor válido';
    }

    return null;
  }

  // ============================================================
  // VALIDAR DESCRIPCIÓN
  // ============================================================

  String? _validateDescription(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingresa una descripción';
    }

    return null;
  }

  // ============================================================
  // VALIDAR TASA
  // ============================================================

  String? _validateRate(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingresa la tasa E.A.';
    }

    final rate =
        double.tryParse(
              value
                  .trim()
                  .replaceAll(',', '.'),
            ) ??
            -1;

    if (rate < 0) {
      return 'Ingresa una tasa válida';
    }

    return null;
  }

  // ============================================================
  // INFORMACIÓN DE LA TARJETA
  // ============================================================

  Widget _buildCardInfo() {
    if (_selectedCard == null) {
      return const SizedBox.shrink();
    }

    final card = _selectedCard!;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.credit_card,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    card.name,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Cupo disponible',
                ),

                Text(
                  formatCurrency(
                    card.availableCredit,
                  ),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 6,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Cupo utilizado',
                ),

                Text(
                  formatCurrency(
                    card.usedAmount,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar compra',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: _isLoadingCards
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _cards.isEmpty
              ? const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(24),
                    child: Text(
                      'No tienes tarjetas de crédito registradas.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : Form(
                  key: _formKey,

                  child: ListView(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    children: [
                      // ==================================================
                      // TARJETA
                      // ==================================================

                      const Text(
                        'Tarjeta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      DropdownButtonFormField<
                          CreditCard>(
                        initialValue:
                            _selectedCard,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Selecciona una tarjeta',
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(
                            Icons.credit_card,
                          ),
                        ),

                        items:
                            _cards.map(
                          (
                            card,
                          ) {
                            return DropdownMenuItem<
                                CreditCard>(
                              value:
                                  card,

                              child: Text(
                                '${card.name} - ${card.bank}',
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            _isSaving
                                ? null
                                : (card) async {
                                    if (card ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedCard =
                                          card;
                                    });

                                    try {
                                      await _refreshSelectedCard();
                                    } catch (_) {
                                      // No hacemos nada aquí.
                                      // El cupo se actualizará
                                      // nuevamente al guardar.
                                    }
                                  },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      _buildCardInfo(),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // VALOR
                      // ==================================================

                      TextFormField(
                        controller:
                            _amountController,

                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Valor de la compra',
                          hintText:
                              'Ej: 800.000',
                          prefixText:
                              '\$ ',
                          border:
                              OutlineInputBorder(),
                        ),

                        validator:
                            _validateAmount,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // DESCRIPCIÓN
                      // ==================================================

                      TextFormField(
                        controller:
                            _descriptionController,

                        textCapitalization:
                            TextCapitalization
                                .sentences,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Descripción',
                          hintText:
                              'Ej: Compra en Mercado Libre',
                          prefixIcon:
                              Icon(
                            Icons.description,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),

                        validator:
                            _validateDescription,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // CATEGORÍA
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            _selectedCategory,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Categoría',
                          prefixIcon:
                              Icon(
                            Icons.category,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),

                        items:
                            _categories.map(
                          (
                            category,
                          ) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  category,

                              child:
                                  Text(
                                category,
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            _isSaving
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedCategory =
                                          value;
                                    });
                                  },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // FECHA
                      // ==================================================

                      InkWell(
                        onTap:
                            _isSaving
                                ? null
                                : _selectDate,

                        borderRadius:
                            BorderRadius
                                .circular(
                          4,
                        ),

                        child:
                            InputDecorator(
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Fecha de compra',
                            prefixIcon:
                                Icon(
                              Icons
                                  .calendar_today,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),

                          child:
                              Text(
                            _formatDate(
                              _purchaseDate,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // CUOTAS
                      // ==================================================

                      DropdownButtonFormField<
                          int>(
                        initialValue:
                            _installments,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Número de cuotas',
                          prefixIcon:
                              Icon(
                            Icons
                                .format_list_numbered,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),

                        items:
                            List.generate(
                          36,
                          (index) {
                            final value =
                                index + 1;

                            return DropdownMenuItem<
                                int>(
                              value:
                                  value,

                              child:
                                  Text(
                                value == 1
                                    ? '1 cuota'
                                    : '$value cuotas',
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            _isSaving
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _installments =
                                          value;
                                    });
                                  },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // TASA E.A.
                      // ==================================================

                      TextFormField(
                        controller:
                            _rateController,

                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Tasa efectiva anual (E.A.)',
                          hintText:
                              'Ej: 28.5',
                          suffixText:
                              '% E.A.',
                          prefixIcon:
                              Icon(
                            Icons.percent,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),

                        validator:
                            _validateRate,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'La tasa corresponde a la tasa E.A. aplicable a esta compra. Más adelante FinTrack calculará los intereses según la fecha, tasa y condiciones de la compra.',
                        style:
                            TextStyle(
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // ==================================================
                      // GUARDAR
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,

                        child:
                            FilledButton.icon(
                          onPressed:
                              _isSaving
                                  ? null
                                  : _savePurchase,

                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                ),

                          label: Text(
                            _isSaving
                                ? 'Guardando...'
                                : 'Registrar compra',
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