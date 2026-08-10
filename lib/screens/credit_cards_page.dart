import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/credit_card.dart';
import '../utils/currency_formatter.dart';
import 'add_credit_card_page.dart';
import 'add_credit_card_purchase_page.dart';
import 'credit_card_detail_page.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({
    super.key,
  });

  @override
  State<CreditCardsPage> createState() =>
      _CreditCardsPageState();
}

class _CreditCardsPageState
    extends State<CreditCardsPage> {
  List<CreditCard> cards = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  // ============================================================
  // CARGAR TARJETAS
  // ============================================================

  Future<void> loadCards() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final result =
          await DatabaseHelper.instance.getCreditCards();

      if (!mounted) return;

      setState(() {
        cards = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
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
  // AGREGAR TARJETA
  // ============================================================

  Future<void> openAddCreditCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddCreditCardPage(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadCards();
    }
  }

  // ============================================================
  // REGISTRAR COMPRA
  // ============================================================

  Future<void> openAddPurchase({
    CreditCard? creditCard,
  }) async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero debes registrar una tarjeta de crédito.',
          ),
        ),
      );

      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddCreditCardPurchasePage(
          creditCard: creditCard,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadCards();
    }
  }

  // ============================================================
  // ABRIR DETALLE
  // ============================================================

  Future<void> openCardDetail(
    CreditCard card,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreditCardDetailPage(
          creditCard: card,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadCards();
    }
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
  // ELIMINAR TARJETA
  // ============================================================

  Future<void> deleteCard(
    CreditCard card,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar tarjeta',
          ),
          content: Text(
            '¿Quieres eliminar "${card.name}"?\n\n'
            'También se eliminarán todas las compras '
            'registradas con esta tarjeta.',
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

    if (!mounted) return;

    if (confirmed != true) {
      return;
    }

    if (card.id == null) {
      return;
    }

    try {
      await DatabaseHelper.instance
          .deleteCreditCard(
        card.id!,
      );

      if (!mounted) return;

      await loadCards();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tarjeta eliminada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la tarjeta: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TARJETA VISUAL
  // ============================================================

  Widget buildCreditCard(
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
        bottom: 16,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          openCardDetail(card);
        },
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ENCABEZADO
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                          BorderRadius.circular(
                        14,
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
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
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

                  PopupMenuButton<String>(
                    onSelected:
                        (value) {
                      if (value ==
                          'detail') {
                        openCardDetail(
                          card,
                        );
                      }

                      if (value ==
                          'purchase') {
                        openAddPurchase(
                          creditCard: card,
                        );
                      }

                      if (value ==
                          'delete') {
                        deleteCard(
                          card,
                        );
                      }
                    },
                    itemBuilder:
                        (context) {
                      return const [
                        PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .visibility_outlined,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Ver detalle',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'purchase',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .shopping_cart_outlined,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Registrar compra',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .delete_outline,
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
                      ];
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // CUPO TOTAL
              // ==================================================

              Text(
                'Cupo total',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                formatCurrency(
                  card.creditLimit,
                ),
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // UTILIZADO / DISPONIBLE
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Utilizado',
                          style:
                              TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          formatCurrency(
                            card.usedAmount,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Disponible',
                          style:
                              TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          formatCurrency(
                            card.availableCredit,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // BARRA DE UTILIZACIÓN
              // ==================================================

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child:
                    LinearProgressIndicator(
                  value: usage,
                  minHeight: 9,
                  backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  color: usageColor,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                '${card.usagePercentage.toStringAsFixed(1)}% utilizado',
                style: TextStyle(
                  color: usageColor,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // FECHAS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        _buildDateInfo(
                      icon: Icons
                          .calendar_today,
                      title:
                          'Fecha de corte',
                      value:
                          card.cutoffDay !=
                                  null
                              ? 'Día ${card.cutoffDay}'
                              : 'No definida',
                    ),
                  ),
                  Expanded(
                    child:
                        _buildDateInfo(
                      icon: Icons
                          .event_available,
                      title:
                          'Fecha de pago',
                      value:
                          card.paymentDueDay !=
                                  null
                              ? 'Día ${card.paymentDueDay}'
                              : 'No definida',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // PAGO MÍNIMO
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .payments_outlined,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'Pago mínimo',
                        style:
                            TextStyle(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),

                    Text(
                      card.minimumPayment >
                              0
                          ? formatCurrency(
                              card.minimumPayment,
                            )
                          : 'No definido',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // BOTÓN REGISTRAR COMPRA
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    openAddPurchase(
                      creditCard: card,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .shopping_cart_outlined,
                  ),
                  label:
                      const Text(
                    'Registrar compra',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ESTADO VACÍO
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No tienes tarjetas',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Agrega tu primera tarjeta de crédito para comenzar a controlar tu cupo y tus compras.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed:
                  openAddCreditCard,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Agregar tarjeta',
              ),
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
          'Mis tarjetas',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : cards.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadCards,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    children: [
                      // ==================================================
                      // BOTÓN REGISTRAR COMPRA
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton.icon(
                          onPressed:
                              () {
                            openAddPurchase();
                          },
                          icon:
                              const Icon(
                            Icons
                                .shopping_cart_outlined,
                          ),
                          label:
                              const Text(
                            'Registrar compra',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // TARJETAS
                      // ==================================================

                      ...cards.map(
                        buildCreditCard,
                      ),
                    ],
                  ),
                ),

      // ==========================================================
      // BOTÓN AGREGAR TARJETA
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            openAddCreditCard,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Agregar tarjeta',
        ),
      ),
    );
  }
}