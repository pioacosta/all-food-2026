import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

// Capa de acceso a datos para altas de platos.
class PlatosService {
  PlatosService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> uploadProductImage({
    required String path,
    required Uint8List bytes,
  }) {
    return _client.storage.from('productos').uploadBinary(path, bytes);
  }

  String getProductImagePublicUrl(String path) {
    return _client.storage.from('productos').getPublicUrl(path);
  }

  Future<void> insertProduct(Map<String, dynamic> payload) {
    return _client.from('productos').insert(payload);
  }
}
