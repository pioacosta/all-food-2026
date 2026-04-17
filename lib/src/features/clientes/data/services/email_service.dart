import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _serviceId = 'service_aek9exh';
  static const _templateAprobado = 'template_iy7jrdh';
  static const _templateRechazado = 'template_ccxy6bu';
  static const _publicKey = 'duBDv7MWwCz3xvr9b';

  static Future<void> enviarEstadoCuenta({
    required String email,
    required String nombre,
    required String estado,
  }) async {
    final templateId =
        estado == 'aprobado' ? _templateAprobado : _templateRechazado;

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': templateId,
        'user_id': _publicKey,
        'template_params': {
          'nombre': nombre,
          'email': email,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar email: ${response.body}');
    }
  }
}