import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMozoPage extends StatefulWidget {
  const ChatMozoPage({super.key});

  @override
  State<ChatMozoPage> createState() => _ChatMozoPageState();
}

class _ChatMozoPageState extends State<ChatMozoPage> {
  final _repo = MesasRepository();

  bool _cargando = true;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _cargarChats();
  }

  Future<void> _cargarChats() async {
    setState(() => _cargando = true);
    try {
      final chats = await _repo.getChatsActivosMozo();
      if (!mounted) return;
      setState(() => _chats = chats);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMapper.toUserMessage(
                error,
                fallbackMessage: 'No se pudieron cargar los chats activos.',
              ),
            ),
            backgroundColor: const Color(0xFF992E2E),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats de clientes')),
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
                  ? const Center(child: LogoSpinner(size: 66, strokeWidth: 4))
                  : _chats.isEmpty
                  ? const Center(
                    child: Text(
                      'No hay chats activos de clientes.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final numeroMesa =
                          (chat['numero_mesa'] as num?)?.toInt() ?? 0;
                      final mensaje = chat['mensaje']?.toString() ?? '';
                      final mesaId = chat['mesa_id'] as String?;
                      final clienteId = chat['cliente_id'] as String?;
                      if (mesaId == null || clienteId == null) {
                        return const SizedBox.shrink();
                      }

                      return InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatMozoDetallePage(
                                    mesaId: mesaId,
                                    numeroMesa: numeroMesa,
                                    clienteId: clienteId,
                                  ),
                            ),
                          );
                          await _cargarChats();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mesa $numeroMesa',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mensaje,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}

class ChatMozoDetallePage extends StatefulWidget {
  const ChatMozoDetallePage({
    required this.mesaId,
    required this.numeroMesa,
    required this.clienteId,
    super.key,
  });

  final String mesaId;
  final int numeroMesa;
  final String clienteId;

  @override
  State<ChatMozoDetallePage> createState() => _ChatMozoDetallePageState();
}

class _ChatMozoDetallePageState extends State<ChatMozoDetallePage> {
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);
    try {
      final data = await _repo.getMensajesChatMesaMozo(
        mesaId: widget.mesaId,
        clienteId: widget.clienteId,
      );
      if (!mounted) return;
      setState(() => _mensajes = data);
      _scrollAlFinal();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMapper.toUserMessage(
                error,
                fallbackMessage: 'No se pudo cargar la conversación.',
              ),
            ),
            backgroundColor: const Color(0xFF992E2E),
          ),
        );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _iniciarSuscripcion() {
    _channel =
        Supabase.instance.client
            .channel('chat_mozo_${widget.mesaId}_${widget.clienteId}')
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
    if (mensaje.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await _repo.enviarMensajeChatMozo(
        mesaId: widget.mesaId,
        numeroMesa: widget.numeroMesa,
        clienteId: widget.clienteId,
        mensaje: mensaje,
      );
      if (!mounted) return;
      _controller.clear();
      await _cargarMensajes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMapper.toUserMessage(
                error,
                fallbackMessage: 'No se pudo enviar el mensaje al cliente.',
              ),
            ),
            backgroundColor: const Color(0xFF992E2E),
          ),
        );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat mesa ${widget.numeroMesa}')),
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
              Expanded(
                child:
                    _cargando
                        ? const Center(
                          child: LogoSpinner(size: 66, strokeWidth: 4),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) {
                            final item = _mensajes[index];
                            final esMozo = item['remitente_perfil'] == 'mozo';
                            return Align(
                              alignment:
                                  esMozo
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      esMozo
                                          ? const Color(0xFF2D6A4F)
                                          : Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  item['mensaje']?.toString() ?? '',
                                  style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Escribe una respuesta...',
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
