import 'package:all_food/src/features/chat/presentation/pages/chat_page.dart';
import 'package:all_food/src/features/consultas/data/repository/consultas_repository.dart';
import 'package:all_food/src/features/consultas/presentation/widgets/consulta_card.dart';
import 'package:all_food/src/features/consultas/presentation/widgets/sin_consultas_widget.dart';
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
  final _pageController = PageController();

  List<Map<String, dynamic>> _consultas = [];
  bool _loading = true;
  bool _puedeVerMensajes = false;
  bool _validandoAcceso = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

      setState(() {
        _consultas = data;
        _puedeVerMensajes = true;
        _validandoAcceso = false;
        _loading = false;
        _currentIndex = 0;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _validandoAcceso = false;
      });
    }
  }

  String _formatHora(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  // Devuelve minutos transcurridos y nivel de urgencia
  ({String texto, Urgencia nivel}) _urgencia(String? iso) {
    if (iso == null) return (texto: '', nivel: Urgencia.normal);
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);

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
                          itemCount: _consultas.length,
                          itemBuilder: (context, index) {
                            final c = _consultas[index];

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
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${_currentIndex + 1} de ${_consultas.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
