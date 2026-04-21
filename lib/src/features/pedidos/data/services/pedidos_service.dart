import 'package:supabase_flutter/supabase_flutter.dart';

class PedidosService {
  PedidosService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> getMiPerfil() async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AuthException('No hay un usuario autenticado.');
    }

    return _client
        .from('perfiles')
        .select('id, perfil, habilitado, nombres, apellidos')
        .eq('id', uid)
        .single();
  }

  Future<Map<String, dynamic>?> getPedidoActivo({
    required String mesaId,
  }) async {
    return _client
        .from('pedidos')
        .select('*')
        .eq('mesa_id', mesaId)
        .neq('estado', 'cerrado')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getPedidoById(String pedidoId) async {
    return _client.from('pedidos').select('*').eq('id', pedidoId).maybeSingle();
  }

  Future<Map<String, dynamic>?> getPerfilById(String userId) async {
    return _client
        .from('perfiles')
        .select('nombres, apellidos')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> createPedido({
    required String mesaId,
    required String clienteId,
  }) async {
    return _client
        .from('pedidos')
        .insert({
          'mesa_id': mesaId,
          'cliente_id': clienteId,
          'estado': 'borrador',
          'subtotal': 0,
          'total': 0,
        })
        .select()
        .single();
  }

  Future<List<Map<String, dynamic>>> getItemsPedido(String pedidoId) async {
    final data = await _client
        .from('pedido_items')
        .select('*')
        .eq('pedido_id', pedidoId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getPedidoItem({
    required String pedidoId,
    required String productoId,
  }) async {
    return _client
        .from('pedido_items')
        .select('*')
        .eq('pedido_id', pedidoId)
        .eq('producto_id', productoId)
        .maybeSingle();
  }

  Future<void> insertPedidoItem(Map<String, dynamic> payload) {
    return _client.from('pedido_items').insert(payload);
  }

  Future<void> updatePedidoItem({
    required String itemId,
    required Map<String, dynamic> payload,
  }) {
    return _client.from('pedido_items').update(payload).eq('id', itemId);
  }

  Future<void> deletePedidoItem(String itemId) {
    return _client.from('pedido_items').delete().eq('id', itemId);
  }

  Future<void> updatePedido({
    required String pedidoId,
    required Map<String, dynamic> payload,
  }) {
    return _client.from('pedidos').update(payload).eq('id', pedidoId);
  }

  Future<List<Map<String, dynamic>>> getPedidosByEstado({
    required List<String> estados,
  }) async {
    if (estados.isEmpty) return [];

    final data = await _client
        .from('pedidos')
        .select('*, mesas(numero)')
        .inFilter('estado', estados)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getItemsSector({
    required String tipoProducto,
  }) async {
    final data = await _client
        .from('pedido_items')
        .select(
          '*, pedidos!inner(id, mesa_id, estado, created_at, mesas(numero))',
        )
        .eq('tipo_producto', tipoProducto)
        .neq('estado', 'listo')
        .inFilter('pedidos.estado', ['confirmado_mozo', 'en_preparacion'])
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getEncuestas() async {
    final data = await _client
        .from('encuestas_satisfaccion')
        .select('*')
        .order('created_at', ascending: false)
        .limit(100);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> insertEncuesta(
    Map<String, dynamic> payload,
  ) async {
    return _client
        .from('encuestas_satisfaccion')
        .insert(payload)
        .select()
        .single();
  }

  Future<Map<String, dynamic>?> getMesaById(String mesaId) async {
    return _client.from('mesas').select('*').eq('id', mesaId).maybeSingle();
  }

  Future<void> liberarMesa(String mesaId) {
    return _client
        .from('mesas')
        .update({'cliente_id': null, 'ocupada': false})
        .eq('id', mesaId);
  }

  Future<Map<String, dynamic>?> getPedidoActivoOCerrado({
    required String mesaId,
  }) async {
    // Primero buscá uno activo (no cerrado)
    final activo = await getPedidoActivo(mesaId: mesaId);
    if (activo != null) return activo;

    // Solo si no hay activo, traé el último cerrado
    // Esto permite detectar el cierre recién ocurrido via Realtime
    // pero nunca confunde un cerrado viejo con un pedido nuevo
    return _client
        .from('pedidos')
        .select('*')
        .eq('mesa_id', mesaId)
        .eq('estado', 'cerrado')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}
