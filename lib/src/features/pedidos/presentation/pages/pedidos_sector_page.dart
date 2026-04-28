import 'package:flutter/material.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidosSectorPage extends StatefulWidget {
  const PedidosSectorPage({required this.sector, super.key});

  final String sector;

  @override
  State<PedidosSectorPage> createState() => _PedidosSectorPageState();
}

class _PedidosSectorPageState extends State<PedidosSectorPage> {
  final _repo = PedidosRepository();

  bool _cargando = true;
  bool _procesando = false;
  List<Map<String, dynamic>> _items = [];

  bool get _esCocina => widget.sector == 'cocina';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data =
          _esCocina
              ? await _repo.getItemsPendientesCocina()
              : await _repo.getItemsPendientesBar();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudieron cargar pedidos del sector.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _marcarListo(Map<String, dynamic> item) async {
    final pedido = item['pedidos'] as Map<String, dynamic>?;
    final pedidoId = pedido?['id'] as String?;
    if (pedidoId == null) return;

    setState(() => _procesando = true);
    try {
      await _repo.marcarItemListo(
        pedidoId: pedidoId,
        itemId: item['id'] as String,
      );

      // �Y?????? Verificar si el pedido completo est?f� listo
      try {
        final mesaMap = pedido?['mesas'] as Map<String, dynamic>?;
        final numeroMesa = mesaMap?['numero']?.toString() ?? '-';

        // Buscar todos los items del pedido y su estado
        final todosItems = await Supabase.instance.client
            .from('pedido_items')
            .select('estado, id')
            .eq('pedido_id', pedidoId);
        final todosListos = todosItems.every(
          (i) => i['estado']?.toString() == 'listo' || i['id'] == item['id'],
        );

        if (todosListos) {
          await Supabase.instance.client.functions.invoke(
            'notificar-sector',
            body: {
              'sector': 'mozo',
              'numeroMesa': numeroMesa,
              'mensaje':
                  '�?"??? Pedido completo listo para entregar - Mesa $numeroMesa',
            },
          );
        }
      } catch (_) {}

      if (!mounted) return;
      _mostrarMensaje('?f�tem marcado como listo.', esError: false);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo marcar el ?f�tem.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) {
      ErrorFeedback.vibrate();
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _esCocina ? 'Sector cocina' : 'Sector bar';
    final agrupados = <String, List<Map<String, dynamic>>>{};

    for (final item in _items) {
      final pedido = item['pedidos'] as Map<String, dynamic>?;
      final mesaMap = pedido?['mesas'] as Map<String, dynamic>?;
      final numeroMesa = mesaMap?['numero']?.toString() ?? '-';
      final key = 'Mesa $numeroMesa';
      agrupados.putIfAbsent(key, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 70, strokeWidth: 4))
                  : agrupados.isEmpty
                  ? const Center(
                    child: Text(
                      'No hay pedidos pendientes en este sector.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: agrupados.keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, groupIndex) {
                      final mesaKey = agrupados.keys.elementAt(groupIndex);
                      final itemsMesa = agrupados[mesaKey]!;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              mesaKey,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < itemsMesa.length; i++) ...[
                              _ItemSectorTile(
                                item: itemsMesa[i],
                                procesando: _procesando,
                                onMarcarListo: () => _marcarListo(itemsMesa[i]),
                              ),
                              if (i < itemsMesa.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}

class _ItemSectorTile extends StatelessWidget {
  const _ItemSectorTile({
    required this.item,
    required this.procesando,
    required this.onMarcarListo,
  });

  final Map<String, dynamic> item;
  final bool procesando;
  final VoidCallback onMarcarListo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item['nombre_snapshot']} x${item['cantidad']}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          FilledButton(
            onPressed: procesando ? null : onMarcarListo,
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }
}
