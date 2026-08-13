import 'dart:convert';

import 'package:http/http.dart' as http;

class PauService {
  // ============================================================
  // PAU - COACH FINANCIERO
  // ============================================================

  static const String name = 'Pau';

  static const String description =
      'Tu coach financiero personal';

  // ============================================================
  // CONFIGURACIÓN GROQ
  // ============================================================

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // IMPORTANTE:
  // Por ahora colocaremos la API Key aquí SOLO para probar.
  // Después la moveremos a una ubicación segura.
  static const String _apiKey =
      '';

  static const String _model =
      'openai/gpt-oss-120b';

  // ============================================================
  // ENVIAR MENSAJE
  // ============================================================

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },

        body: jsonEncode({
          'model': _model,

          'messages': [
            {
              'role': 'system',
              'content': '''
Eres Pau, el coach financiero de FinTrack.

Tu objetivo es ayudar al usuario a comprender y organizar
mejor sus finanzas personales.

Debes responder en español.

Sé clara, amigable y práctica.

No inventes información financiera del usuario.
Solo utiliza los datos que el usuario proporcione.

No prometas resultados financieros.

Cuando sea necesario, explica conceptos financieros
de forma sencilla para que una persona pueda entenderlos.

Tu nombre es Pau.
''',
            },
            {
              'role': 'user',
              'content': message,
            },
          ],

          'temperature': 0.7,
        }),
      );

      // ========================================================
      // RESPUESTA EXITOSA
      // ========================================================

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final choices =
            data['choices'] as List?;

        if (choices == null ||
            choices.isEmpty) {
          return 'Pau no recibió una respuesta válida.';
        }

        final messageData =
            choices.first['message'];

        final content =
            messageData['content'];

        if (content == null ||
            content.toString().trim().isEmpty) {
          return 'Pau no pudo generar una respuesta.';
        }

        return content.toString().trim();
      }

      // ========================================================
      // ERROR DE API
      // ========================================================

      try {
        final errorData =
            jsonDecode(response.body);

        final error =
            errorData['error'];

        if (error != null) {
          final errorMessage =
              error['message'];

          if (errorMessage != null) {
            return 'Pau tuvo un problema: $errorMessage';
          }
        }
      } catch (_) {
        // Si la respuesta de error no es JSON,
        // continuamos con el mensaje genérico.
      }

      return '''
Pau no pudo responder en este momento.

Código del servidor: ${response.statusCode}
''';
    } catch (e) {
      return '''
No se pudo conectar con Pau.

Verifica que tengas conexión a Internet.
''';
    }
  }
}