import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pau_financial_context.dart';

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

  Future<String> sendMessage(
    String message,
  ) async {
    try {
      // --------------------------------------------------------
      // CARGAR DATOS FINANCIEROS
      // --------------------------------------------------------

      final financialContext =
          await PauFinancialContext.load();

      final financialData =
          financialContext.buildContext();

      // --------------------------------------------------------
      // ENVIAR A GROQ
      // --------------------------------------------------------

      final response = await http.post(
        Uri.parse(_apiUrl),

        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $_apiKey',
        },

        body: jsonEncode({
          'model': _model,

          'messages': [
            {
              'role': 'system',
              'content': '''
Eres Pau, el coach financiero de FinTrack.

Tu objetivo es ayudar al usuario a comprender,
organizar y mejorar sus finanzas personales.

Debes responder siempre en español.

Sé clara, amigable, práctica y honesta.

============================================================
REGLAS IMPORTANTES
============================================================

1. Utiliza los datos financieros proporcionados por FinTrack
   para analizar la situación del usuario.

2. NO inventes datos que no estén presentes.

3. Si un dato no está disponible, dilo claramente.

4. Puedes realizar cálculos utilizando los datos proporcionados.

5. Puedes comparar ingresos, gastos, saldos, deudas,
   utilización de tarjetas y compras.

6. Puedes señalar posibles problemas financieros,
   pero no debes presentar tus recomendaciones como
   asesoría financiera profesional.

7. No prometas resultados financieros.

8. No juzgues al usuario por sus decisiones financieras.

9. Explica los conceptos financieros de manera sencilla.

10. Cuando hagas una recomendación, explica brevemente
    por qué la estás haciendo.

11. Tu nombre es Pau.

============================================================
DATOS FINANCIEROS DE FINTRACK
============================================================

$financialData

============================================================

Utiliza estos datos como contexto financiero actual
del usuario.

Si el usuario pregunta algo que pueda responderse
utilizando estos datos, analízalos antes de responder.
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