import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _scrollController = ScrollController();

  bool _cargando = true;
  bool _enviando = false;
  RealtimeChannel? _channel;
  List<Map<String, dynamic>> _mensajes = [];

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _iniciarSuscripcion();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);
    try {
      final data = await _repo.getMensajesChatMesaCliente(
        mesaId: widget.mesaId,
      );
      if (!mounted) return;
      setState(() => _mensajes = data);
      _scrollAlFinal();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudieron cargar los mensajes del chat.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _iniciarSuscripcion() {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    _channel =
        client
            .channel('chat_cliente_${widget.mesaId}_$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_mensajes',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'mesa_id',
                value: widget.mesaId,
              ),
              callback: (_) {
                _cargarMensajes();
              },
            )
            .subscribe();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _controller.text.trim();
    if (mensaje.isEmpty) {
      _mostrarMensaje('Escribe un mensaje antes de enviarlo.', esError: true);
      return;
    }

    setState(() => _enviando = true);
    try {
      await _repo.enviarMensajeChatCliente(
        mesaId: widget.mesaId,
        numeroMesa: widget.numeroMesa,
        mensaje: mensaje,
      );

      if (!mounted) return;
      _controller.clear();
      await _cargarMensajes();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo enviar el mensaje al mozo.',
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
      appBar: AppBar(title: Text('Chat con mozo - Mesa ${widget.numeroMesa}')),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _enviando
                                ? null
                                : () => _cargarMensajeRapido(
                                  'Necesito cubiertos y servilletas, por favor.',
                                ),
                        child: const Text('Pedido rápido'),
                      ),
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
                        : _mensajes.isEmpty
                        ? const Center(
                          child: Text(
                            'Todavía no hay mensajes en el chat.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) {
                            final item = _mensajes[index];
                            final esCliente =
                                item['remitente_perfil'] == 'cliente';
                            final fecha = DateTime.tryParse(
                              item['created_at']?.toString() ?? '',
                            );
                            final hora =
                                fecha == null
                                    ? '--:--'
                                    : '${fecha.toLocal().hour.toString().padLeft(2, '0')}:${fecha.toLocal().minute.toString().padLeft(2, '0')}';

                            return Align(
                              alignment:
                                  esCliente
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  9,
                                  12,
                                  8,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      esCliente
                                          ? const Color(0xFF2D6A4F)
                                          : Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['mensaje']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      esCliente ? 'Tú - $hora' : 'Mozo - $hora',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: 2,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _enviando ? null : _enviarMensaje,
                      child:
                          _enviando
                              ? const LogoSpinner(size: 18, strokeWidth: 2)
                              : const Text('Enviar'),
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
