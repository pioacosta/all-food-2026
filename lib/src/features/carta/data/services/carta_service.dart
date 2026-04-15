import 'package:supabase_flutter/supabase_flutter.dart';

class CartaService {
  CartaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Trae productos filtrados por tipo y opcionalmente por nombre.
  /// [tipo] puede ser 'plato' o 'bebida'.
  /// [nombre] es opcional para búsqueda.
  Future<List<Map<String, dynamic>>> getProductos({
    required String tipo,
    String? nombre,
  }) async {
    var query = _client
        .from('productos')
        .select()
        .eq('tipo', tipo)
        .eq('habilitado', true);

    if (nombre != null && nombre.trim().isNotEmpty) {
      query = query.ilike('nombre', '%${nombre.trim()}%');
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}