import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// Encapsula las llamadas crudas a Supabase (Auth, Storage y tablas).
// Esta capa no contiene reglas de negocio, solo acceso a backend.
class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  // Sube la foto de perfil al bucket de avatares.
  Future<void> uploadAvatar({required String fileName, required File file}) {
    return _client.storage.from('avatares').upload(fileName, file);
  }

  // Devuelve la URL publica para persistirla en la tabla de perfiles.
  String getAvatarPublicUrl(String fileName) {
    return _client.storage.from('avatares').getPublicUrl(fileName);
  }

  Future<void> insertProfile(Map<String, dynamic> profileData) {
    return _client.from('perfiles').insert(profileData);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
