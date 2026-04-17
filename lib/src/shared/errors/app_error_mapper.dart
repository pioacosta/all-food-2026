import 'dart:async';
import 'dart:io';

import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Traduce errores tecnicos a mensajes amigables y consistentes para UI.
class AppErrorMapper {
  static String toUserMessage(Object error, {required String fallbackMessage}) {
    // Errores de dominio ya vienen listos para mostrar.
    if (error is AppException) {
      return error.message;
    }

    // Errores de autenticacion de Supabase.
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      // Personalización del mensaje del Bug 1
      if (message.contains('already registered') ||
          message.contains('user_already_exists')) {
        return 'Este correo electrónico ya se encuentra registrado.';
      }
      return error.message;
    }

    // Errores de base de datos (queries/RPC).
    if (error is PostgrestException) {
      final detailsText = error.details?.toString().trim() ?? '';
      final hintText = error.hint?.toString().trim() ?? '';
      final parts =
          <String>[
            error.message.trim(),
            detailsText,
            hintText,
          ].where((p) => p.isNotEmpty).toList();

      if (parts.isEmpty) return fallbackMessage;
      return parts.join('\n');
    }

    // Errores de red frecuentes.
    if (error is SocketException || error is TimeoutException) {
      return 'No se pudo conectar con el servidor. Intenta nuevamente.';
    }

    return fallbackMessage;
  }
}
