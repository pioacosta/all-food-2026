import 'package:all_food/src/features/chat/presentation/pages/chat_page.dart';
import 'package:all_food/src/features/consultas/data/repository/consultas_repository.dart';
import 'package:all_food/src/features/consultas/presentation/widgets/consulta_card.dart';
import 'package:all_food/src/features/consultas/presentation/widgets/sin_consultas_widget.dart';
import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ConsultasPage extends StatefulWidget {
  const ConsultasPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<ConsultasPage> createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  final _repo = GestionServiciosRepository();
  static const int _itemsPorPagina = 5;

  List<Map<String, dynamic>> _consultas = [];
  bool _loading = true;
  bool _puedeVerMensajes = false;
  bool _validandoAcceso = true;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _totalPaginas {
    if (_consultas.isEmpty) return 1;
    return (_consultas.length / _itemsPorPagina).ceil();
  }

  List<Map<String, dynamic>> get _consultasPagina {
    final inicio = _paginaActual * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, _consultas.length);
    if (inicio >= _consultas.length) return const [];
    return _consultas.sublist(inicio, fin);
  }

  DateTime _timestampOrden(Map<String, dynamic> consulta) {
    final ultimo = consulta['ultimo_mensaje'] as Map<String, dynamic>?;
    final createdAt = ultimo?['created_at'] as String?;
    if (createdAt == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      final parsed = DateTime.parse(createdAt);
      return parsed.isUtc ? parsed : parsed.toUtc();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  void _irPaginaAnterior() {
    if (_paginaActual == 0) return;
    setState(() => _paginaActual -= 1);
  }

  void _irPaginaSiguiente() {
    if (_paginaActual >= _totalPaginas - 1) return;
    setState(() => _paginaActual += 1);
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _validandoAcceso = true;
    });

    try {
      final autorizado = await _repo.canCurrentUserListMessages();
      if (!mounted) return;

      if (!autorizado) {
        setState(() {
          _puedeVerMensajes = false;
          _validandoAcceso = false;
          _loading = false;
        });
        return;
      }

      final data = await _repo.getConsultasAbiertas();
      if (!mounted) return;

      data.sort((a, b) => _timestampOrden(b).compareTo(_timestampOrden(a)));

      setState(() {
        _consultas = data;
        _puedeVerMensajes = true;
        _validandoAcceso = false;
        _loading = false;
        _paginaActual = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _validandoAcceso = false;
      });
    }
  }

  String _formatHora(String? iso) {
    return BuenosAiresTime.formatHourMinuteFromIso(iso);
  }

  DateTime? _parseBuenosAires(String? iso) {
    return BuenosAiresTime.tryParseToBuenosAires(iso);
  }

  // Devuelve minutos transcurridos y nivel de urgencia
  ({String texto, Urgencia nivel}) _urgencia(String? iso) {
    final dt = _parseBuenosAires(iso);
    if (dt == null) return (texto: '', nivel: Urgencia.normal);
    try {
      final ahoraBa = BuenosAiresTime.now();
      final diff = ahoraBa.difference(dt);

      String texto;
      if (diff.inMinutes < 1) {
        texto = 'Ahora mismo';
      } else if (diff.inMinutes < 60) {
        texto = 'hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        final horas = diff.inHours;
        final mins = diff.inMinutes % 60;
        texto = mins > 0 ? 'hace ${horas}h ${mins}min' : 'hace ${horas}h';
      } else {
        final dias = diff.inDays;
        texto = dias == 1 ? 'hace 1 día' : 'hace $dias días';
      }

      Urgencia nivel;
      if (diff.inMinutes < 1 || diff.inMinutes < 5) {
        nivel = Urgencia.normal;
      } else if (diff.inMinutes < 15) {
        nivel = Urgencia.media;
      } else {
        nivel = Urgencia.urgente;
      }

      return (texto: texto, nivel: nivel);
    } catch (_) {
      return (texto: '', nivel: Urgencia.normal);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _validandoAcceso) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    if (!_puedeVerMensajes) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultas de clientes')),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.white38),
                    SizedBox(height: 16),
                    Text(
                      'Acceso denegado',
                      style: TextStyle(
                        fontFamily: 'ArchivoBlack',
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Solo el personal autorizado puede ver esta sección.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas de clientes'),
        actions: [
          // ── Botón refresh en el AppBar ─────────────────────────
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Column(
                  children: [
                    // const Text(
                    //   'Consultas activas',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     fontFamily: 'ArchivoBlack',
                    //     fontSize: 32,
                    //     color: Colors.white,
                    //     letterSpacing: -1.5,
                    //   ),
                    // ),
                    // const SizedBox(height: 6),
                    // Text(
                    //   _consultas.isEmpty
                    //       ? 'Sin mesas esperando atención'
                    //       : 'Deslizá para ver cada consulta',
                    //   textAlign: TextAlign.center,
                    //   style: const TextStyle(
                    //     color: Colors.white70,
                    //     fontSize: 18,
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    if (_consultas.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_consultas.length} consulta${_consultas.length != 1 ? 's' : ''} activa${_consultas.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── Cards / empty state ──────────────────────────────
              Expanded(
                child:
                    _consultas.isEmpty
                        ? const SinConsultasWidget()
                        : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _consultasPagina.length,
                          itemBuilder: (context, index) {
                            final c = _consultasPagina[index];

                            final mesaNumero =
                                c['mesas']?['numero']?.toString() ?? '-';
                            final nombres =
                                c['perfiles']?['nombres'] as String? ?? '';
                            final apellidos =
                                c['perfiles']?['apellidos'] as String? ?? '';
                            final nombreCliente =
                                '$nombres $apellidos'.trim().isEmpty
                                    ? 'Cliente'
                                    : '$nombres $apellidos'.trim();

                            final ultimoMensaje =
                                c['ultimo_mensaje'] as Map<String, dynamic>?;
                            final previewTexto =
                                ultimoMensaje?['mensaje'] as String? ??
                                'Sin mensajes aún';
                            final previewHora = _formatHora(
                              ultimoMensaje?['created_at'],
                            );
                            final urg = _urgencia(ultimoMensaje?['created_at']);

                            return ConsultaCard(
                              mesaNumero: mesaNumero,
                              nombreCliente: nombreCliente,
                              previewTexto: previewTexto,
                              previewHora: previewHora,
                              urgenciaTexto: urg.texto,
                              urgenciaNivel: urg.nivel,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatPage(
                                            mesaId: c['mesa_id'],
                                            clienteId: c['cliente_id'],
                                          ),
                                    ),
                                  ).then((_) => _cargar()),
                            );
                          },
                        ),
              ),

              // ── Indicador de página ──────────────────────────────
              if (_consultas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _paginaActual == 0 ? null : _irPaginaAnterior,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: const Color(0xFF4A0E10),
                            backgroundColor: Colors.white,
                            disabledForegroundColor: Colors.white54,
                            disabledBackgroundColor: const Color(0xFF7A2021),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.3,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Página ${_paginaActual + 1} / $_totalPaginas',
                        style: const TextStyle(
                          color: Color(0xFFFFE3E3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _paginaActual >= _totalPaginas - 1
                                  ? null
                                  : _irPaginaSiguiente,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: const Color(0xFF4A0E10),
                            backgroundColor: Colors.white,
                            disabledForegroundColor: Colors.white54,
                            disabledBackgroundColor: const Color(0xFF7A2021),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.3,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Siguiente'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
