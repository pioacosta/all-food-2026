import 'package:flutter/material.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
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
  static const int _mesasPorPagina = 4;

  bool _cargando = true;
  bool _procesando = false;
  List<Map<String, dynamic>> _items = [];
  int _paginaActual = 0;

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

      // ?Y?????? Verificar si el pedido completo est?f? listo
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
                  'Pedido completo listo para entregar - Mesa $numeroMesa',
            },
          );
        }
      } catch (_) {}

      if (!mounted) return;
      _mostrarMensaje('Ítem marcado como listo.', esError: false);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo marcar el ítem.',
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
    final agrupados = <String, Map<String, dynamic>>{};

    for (final item in _items) {
      final pedido = item['pedidos'] as Map<String, dynamic>?;
      final mesaMap = pedido?['mesas'] as Map<String, dynamic>?;
      final numeroMesa = mesaMap?['numero']?.toString() ?? '-';
      final key = 'Mesa $numeroMesa';
      final grupo = agrupados.putIfAbsent(
        key,
        () => <String, dynamic>{
          'createdAt': pedido?['created_at'],
          'items': <Map<String, dynamic>>[],
        },
      );
      final itemsGrupo = grupo['items'] as List<Map<String, dynamic>>;
      itemsGrupo.add(item);
      grupo['createdAt'] ??= pedido?['created_at'];
    }

    final clavesMesas = agrupados.keys.toList();
    final totalPaginas =
        clavesMesas.isEmpty ? 1 : (clavesMesas.length / _mesasPorPagina).ceil();
    if (_paginaActual > totalPaginas - 1) {
      _paginaActual = (totalPaginas - 1).clamp(0, 999999);
    }
    final inicio = _paginaActual * _mesasPorPagina;
    final fin = (inicio + _mesasPorPagina).clamp(0, clavesMesas.length);
    final mesasPagina =
        inicio >= clavesMesas.length
            ? const <String>[]
            : clavesMesas.sublist(inicio, fin);

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
                  ? const _EstadoVacioSector(
                    mensaje: 'No hay pedidos pendientes en este sector.',
                  )
                  : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        Expanded(
                          child: _PaginaCardsMesas(
                            cantidadItems: mesasPagina.length,
                            itemBuilder: (context, index) {
                              final mesaKey = mesasPagina[index];
                              final grupo = agrupados[mesaKey]!;
                              final itemsMesa = List<Map<String, dynamic>>.from(
                                grupo['items'] as List<Map<String, dynamic>>,
                              );
                              final fechaHora =
                                  BuenosAiresTime.formatDateTimeFromIso(
                                    grupo['createdAt']?.toString() ?? '',
                                  );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      mesaKey,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fecha y hora: $fechaHora (Buenos Aires)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: itemsMesa.length,
                                        separatorBuilder:
                                            (_, __) =>
                                                const SizedBox(height: 8),
                                        itemBuilder: (context, itemIndex) {
                                          return _ItemSectorTile(
                                            item: itemsMesa[itemIndex],
                                            procesando: _procesando,
                                            onMarcarListo:
                                                () => _marcarListo(
                                                  itemsMesa[itemIndex],
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PaginacionSector(
                          paginaActual: _paginaActual,
                          totalPaginas: totalPaginas,
                          onAnterior: () {
                            if (_paginaActual <= 0) return;
                            setState(() => _paginaActual -= 1);
                          },
                          onSiguiente: () {
                            if (_paginaActual >= totalPaginas - 1) return;
                            setState(() => _paginaActual += 1);
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class _EstadoVacioSector extends StatelessWidget {
  const _EstadoVacioSector({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.disabled_by_default_rounded,
              size: 170,
              color: Colors.white.withValues(alpha: 0.82),
            ),
            const SizedBox(height: 24),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginaCardsMesas extends StatelessWidget {
  const _PaginaCardsMesas({
    required this.cantidadItems,
    required this.itemBuilder,
  });

  final int cantidadItems;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (cantidadItems <= 0) return const SizedBox.shrink();
    return Column(
      children: List.generate(cantidadItems, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: index == cantidadItems - 1 ? 0 : 10,
            ),
            child: itemBuilder(context, index),
          ),
        );
      }),
    );
  }
}

class _PaginacionSector extends StatelessWidget {
  const _PaginacionSector({
    required this.paginaActual,
    required this.totalPaginas,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final int paginaActual;
  final int totalPaginas;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final puedeAnterior = paginaActual > 0;
    final puedeSiguiente = paginaActual < totalPaginas - 1;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: puedeAnterior ? onAnterior : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFF4A0E10),
              backgroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              disabledBackgroundColor: const Color(0xFF7A2021),
              side: const BorderSide(color: Colors.white, width: 1.4),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Página ${paginaActual + 1} / $totalPaginas',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: puedeSiguiente ? onSiguiente : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFF4A0E10),
              backgroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              disabledBackgroundColor: const Color(0xFF7A2021),
              side: const BorderSide(color: Colors.white, width: 1.4),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Siguiente'),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item['nombre_snapshot']} x${item['cantidad']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: procesando ? null : onMarcarListo,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 42),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }
}
