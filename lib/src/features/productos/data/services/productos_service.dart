import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Capa de acceso a datos para productos.
class ProductosService {
  ProductosService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// ID del usuario actual
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Subir imagen a storage
  Future<void> uploadProductImage({
    required String path,
    required Uint8List bytes,
  }) async {
    await _client.storage.from('productos').uploadBinary(path, bytes);
  }

  /// Obtener URL pública de la imagen
  String getProductImagePublicUrl(String path) {
    return _client.storage.from('productos').getPublicUrl(path);
  }

  /// Insertar producto en la DB
  Future<void> insertProduct(Map<String, dynamic> payload) async {
    await _client.from('productos').insert(payload);
  }

  /// Obtener perfil del usuario (clave para roles)
  Future<String?> getUserPerfil() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data = await _client
        .from('perfiles')
        .select('perfil')
        .eq('id', userId)
        .single();

    return data['perfil'] as String?;
  }
}