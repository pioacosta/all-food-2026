import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ConsultaMozoPage extends StatefulWidget {
  const ConsultaMozoPage({
    required this.mesaId,
    required this.numeroMesa,
    super.key,
  });

  final String mesaId;
  final int numeroMesa;

  @override
  State<ConsultaMozoPage> createState() => _ConsultaMozoPageState();
}

class _ConsultaMozoPageState extends State<ConsultaMozoPage> {
  final _repo = MesasRepository();
  final _controller = TextEditingController();

  bool _cargando = true;
  bool _enviando = false;
  List<Map<String, dynamic>> _consultas = [];

  @override
  void initState() {
    super.initState();
    _cargarConsultas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarConsultas() async {
    setState(() => _cargando = true);
    try {
      final data = await _repo.getConsultasRapidasDeMiMesa(
        mesaId: widget.mesaId,
      );
      if (!mounted) return;
      setState(() {
        _consultas = data;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudieron cargar las consultas al mozo.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _enviarConsulta() async {
    final mensaje = _controller.text.trim();
    if (mensaje.isEmpty) {
      _mostrarMensaje('Escribe tu consulta antes de enviarla.', esError: true);
      return;
    }

    setState(() => _enviando = true);
    try {
      await _repo.enviarConsultaRapidaMozo(
        mesaId: widget.mesaId,
        numeroMesa: widget.numeroMesa,
        mensaje: mensaje,
      );

      if (!mounted) return;
      _controller.clear();
      _mostrarMensaje('Consulta enviada al mozo.', esError: false);
      await _cargarConsultas();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo enviar la consulta.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _cargarMensajeRapido(String texto) {
    _controller.text = texto;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Consulta al mozo - Mesa ${widget.numeroMesa}'),
      ),
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
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText:
                            'Ejemplo: Necesito servilletas en la mesa, por favor.',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _enviando
                                    ? null
                                    : () => _cargarMensajeRapido(
                                      '¿Podrías acercarte a la mesa cuando puedas?',
                                    ),
                            child: const Text('Llamar al mozo'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _enviando ? null : _enviarConsulta,
                            child:
                                _enviando
                                    ? const LogoSpinner(
                                      size: 20,
                                      strokeWidth: 2,
                                    )
                                    : const Text('Enviar consulta'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _cargando
                        ? const Center(
                          child: LogoSpinner(size: 64, strokeWidth: 4),
                        )
                        : _consultas.isEmpty
                        ? const Center(
                          child: Text(
                            'Todavía no enviaste consultas al mozo.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                          itemCount: _consultas.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _consultas[index];
                            final respondida = item['estado'] == 'respondida';
                            final fecha = DateTime.tryParse(
                              item['created_at']?.toString() ?? '',
                            );
                            final hora =
                                fecha == null
                                    ? '--:--'
                                    : '${fecha.toLocal().hour.toString().padLeft(2, '0')}:${fecha.toLocal().minute.toString().padLeft(2, '0')}';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Mesa ${item['numero_mesa'] ?? widget.numeroMesa}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        hora,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['mensaje']?.toString() ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    respondida
                                        ? 'Respondida'
                                        : 'Pendiente de respuesta',
                                    style: TextStyle(
                                      color:
                                          respondida
                                              ? const Color(0xFFB8F5C3)
                                              : const Color(0xFFFFE08A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((item['respuesta_mensaje'] as String?)
                                          ?.isNotEmpty ==
                                      true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Mozo: ${item['respuesta_mensaje']}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
