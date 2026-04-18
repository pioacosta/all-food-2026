import 'package:supabase_flutter/supabase_flutter.dart';

class CartaService {
  CartaService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Trae productos filtrados opcionalmente por tipo y nombre.
  /// [tipo] puede ser 'plato' o 'bebida'. Si es null, trae todos.
  /// [nombre] es opcional para búsqueda.
  Future<List<Map<String, dynamic>>> getProductos({
    String? tipo,
    String? nombre,
  }) async {
    var query = _client.from('productos').select().eq('habilitado', true);

    if (tipo != null && tipo.trim().isNotEmpty) {
      query = query.eq('tipo', tipo);
    }

    if (nombre != null && nombre.trim().isNotEmpty) {
      query = query.ilike('nombre', '%${nombre.trim()}%');
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Trae un producto por su ID.
  Future<Map<String, dynamic>?> getProductoById(String id) async {
    final data =
        await _client
            .from('productos')
            .select()
            .eq('id', id)
            .eq('habilitado', true)
            .maybeSingle();
    return data;
  }

  Future<String?> getUserPerfil() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data =
        await _client
            .from('perfiles')
            .select('perfil')
            .eq('id', userId)
            .single();
    return data['perfil'] as String?;
  }

  Future<void> updateProducto({
    required String productoId,
    required Map<String, dynamic> payload,
  }) async {
    await _client
        .from('productos')
        .update(payload)
        .eq('id', productoId)
        .eq('habilitado', true);
  }

  Future<void> softDeleteProducto(String productoId) async {
    await _client
        .from('productos')
        .update({'habilitado': false})
        .eq('id', productoId)
        .eq('habilitado', true);
  }
}
