import 'package:flutter/material.dart';

import '../services/pau_service.dart';

class PauPage extends StatefulWidget {
  const PauPage({super.key});

  @override
  State<PauPage> createState() => _PauPageState();
}

class _PauPageState extends State<PauPage> {
  final PauService _pauService = PauService();

  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      const _ChatMessage(
        text:
            'Hola, soy Pau 👋\n\nSoy tu coach financiero personal. '
            'Puedes preguntarme sobre tus gastos, cuentas, tarjetas '
            'y la forma de organizar mejor tu dinero.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // ENVIAR MENSAJE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isLoading) {
      return;
    }

    _controller.clear();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response =
          await _pauService.sendMessage(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: response,
            isUser: false,
          ),
        );

        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Lo siento, ocurrió un error al comunicarme contigo.',
            isUser: false,
          ),
        );

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BAJAR CHAT
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(
                Icons.auto_awesome,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Pau',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // MENSAJES
          // ======================================================

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.all(16),
              itemCount: _messages.length +
                  (_isLoading ? 1 : 0),
              itemBuilder:
                  (context, index) {
                if (_isLoading &&
                    index ==
                        _messages.length) {
                  return const _TypingIndicator();
                }

                final message =
                    _messages[index];

                return _buildMessage(
                  message,
                );
              },
            ),
          ),

          // ======================================================
          // CAMPO DE MENSAJE
          // ======================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction.newline,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Habla con Pau...',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted:
                          (_) {
                        _sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  IconButton.filled(
                    onPressed:
                        _isLoading
                            ? null
                            : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BURBUJA
  // ============================================================

  Widget _buildMessage(
    _ChatMessage message,
  ) {
    final isUser =
        message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 320,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: isUser
              ? Theme.of(context)
                  .colorScheme
                  .primary
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? Theme.of(context)
                    .colorScheme
                    .onPrimary
                : null,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MENSAJE
// ================================================================

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}

// ================================================================
// INDICADOR
// ================================================================

class _TypingIndicator
    extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child: const Text(
          'Pau está pensando...',
        ),
      ),
    );
  }
}