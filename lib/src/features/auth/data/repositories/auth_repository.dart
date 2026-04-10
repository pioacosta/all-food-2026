import 'dart:io';

import 'package:all_food/src/features/auth/data/services/auth_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Excepcion de negocio para mostrar mensajes claros a la UI.
class AuthFlowException extends AppException {
  const AuthFlowException(super.message);
}

// Orquesta los casos de uso de autenticacion para desacoplar la UI.
class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  Future<AuthResponse> loginWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _service.signInWithPassword(email: email, password: password);
  }

  Future<void> registerClient({
    required String nombres,
    required String apellidos,
    required String dni,
    required String correo,
    required String password,
    required File foto,
  }) async {
    // 1) Crear usuario en Supabase Auth.
    final response = await _service.signUp(email: correo, password: password);
    final user = response.user;

    if (user == null) {
      throw AuthFlowException('No fue posible crear la cuenta.');
    }

    final userId = user.id;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

    // 2) Subir avatar del cliente a Storage.
    await _service.uploadAvatar(fileName: fileName, file: foto);

    final fotoUrl = _service.getAvatarPublicUrl(fileName);

    // 3) Persistir el perfil de negocio vinculado al usuario auth.
    await _service.insertProfile({
      'id': userId,
      'nombres': nombres,
      'apellidos': apellidos,
      'dni': dni,
      'correo': correo,
      'perfil': 'cliente_registrado',
      'estado_registro': 'pendiente_aprobacion',
      'foto_url': fotoUrl,
      'habilitado': false,
    });

    // 4) Cerrar sesion para mantener el flujo de aprobacion manual.
    await _service.signOut();
  }
}
