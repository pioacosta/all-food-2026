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
      final detail = error.message.trim();
      return detail.isEmpty ? fallbackMessage : detail;
    }

    // Errores de base de datos (queries/RPC).
    if (error is PostgrestException) {
      final detail = error.message.trim();
      return detail.isEmpty ? fallbackMessage : detail;
    }

    // Errores de red frecuentes.
    if (error is SocketException || error is TimeoutException) {
      return 'No se pudo conectar con el servidor. Intenta nuevamente.';
    }

    return fallbackMessage;
  }
}
