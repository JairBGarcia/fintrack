import 'package:flutter/material.dart';

import '../services/pau_service.dart';

class PauTestPage extends StatefulWidget {
  const PauTestPage({super.key});

  @override
  State<PauTestPage> createState() => _PauTestPageState();
}

class _PauTestPageState extends State<PauTestPage> {
  final PauService _pauService = PauService();

  final TextEditingController _controller =
      TextEditingController();

  String _response = '';

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response =
          await _pauService.sendMessage(message);

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Probar Pau'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pau - Coach financiero',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              PauService.description,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Mensaje para Pau',
                hintText:
                    'Ej: ¿Cómo puedo organizar mis gastos?',
                border: OutlineInputBorder(),
              ),

              maxLines: 3,

              onSubmitted: (_) {
                _sendMessage();
              },
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed:
                  _isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send),
              label: Text(
                _isLoading
                    ? 'Pau está pensando...'
                    : 'Preguntarle a Pau',
              ),
            ),

            const SizedBox(height: 24),

            if (_response.isNotEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        child: Icon(
                          Icons.auto_awesome,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          _response,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}