import 'package:all_food/src/features/chat/data/repository/chat-repository.dart';
import 'package:all_food/src/features/chat/presentation/pages/widgets/burbuja_mensaje.dart';
import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.mesaId, required this.clienteId});

  final String mesaId;
  final String clienteId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _consultaId;
  bool _loading = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final id = await _repo.iniciarChat(
        mesaId: widget.mesaId,
        clienteId: widget.clienteId,
      );
      if (!mounted) return;
      setState(() {
        _consultaId = id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar el chat: $e'),
          backgroundColor: const Color(0xFF992E2E),
        ),
      );
    }
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _consultaId == null || _enviando) return;

    setState(() => _enviando = true);
    _controller.clear();

    try {
      await _repo.enviarMensaje(consultaId: _consultaId!, mensaje: texto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar: $e'),
          backgroundColor: const Color(0xFF992E2E),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    final userId = _repo.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Consulta al mozo')),
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
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                // child: Column(
                //   children: const [
                //     Text(
                //       'Consulta al mozo',
                //       textAlign: TextAlign.center,
                //       style: TextStyle(
                //         fontFamily: 'ArchivoBlack',
                //         fontSize: 32,
                //         color: Colors.white,
                //         letterSpacing: -1.5,
                //       ),
                //     ),
                //     SizedBox(height: 4),
                //     Text(
                //       'El mozo responderá a la brevedad',
                //       textAlign: TextAlign.center,
                //       style: TextStyle(color: Colors.white70, fontSize: 18),
                //     ),
                //   ],
                // ),
              ),

              // ── Mensajes ────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211317),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8D5A5F),
                      width: 0.9,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child:
                        _consultaId == null
                            ? const Center(
                              child: Text(
                                'No se pudo iniciar el chat.',
                                style: TextStyle(color: Color(0xFFFFCDCD)),
                              ),
                            )
                            : StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _repo.mensajes(_consultaId!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: LogoSpinner(
                                      size: 88,
                                      strokeWidth: 5,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  );
                                }

                                final mensajes = snapshot.data!;

                                if (mensajes.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 48,
                                          color: const Color(0xFFFFD4D4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Enviá tu primera consulta',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD4D4),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  itemCount: mensajes.length,
                                  itemBuilder: (context, index) {
                                    final m = mensajes[index];

                                    return BurbujaMensaje(
                                      mensaje: m['mensaje'],
                                      esMio: m['emisor_id'] == userId,
                                      hora: _formatFechaHora(
                                        m['created_at'],
                                      ), // Tu función de formato
                                      nombreEmisor: m['nombre_emisor'],
                                      perfilEmisor:
                                          m['perfil_emisor'], // Aquí llega 'mozo' o lo que sea
                                      numeroMesa: m['numero_mesa'],
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ),
              ),

              // ── Input ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A171B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8D5A5F)),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                            color: Color(0xFFFFEAEA),
                            fontSize: 15,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          onSubmitted: (_) => _enviar(),
                          decoration: InputDecoration(
                            hintText: 'Escribí un mensaje...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFD8B4B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _enviar,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              _enviando
                                  ? const Color(
                                    0xFFFFDCC7,
                                  ).withValues(alpha: 0.5)
                                  : const Color(0xFFFFDCC7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            _enviando
                                ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF5B1718),
                                  ),
                                )
                                : const Icon(
                                  Icons.send_rounded,
                                  color: Color(0xFF5B1718),
                                  size: 22,
                                ),
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

  // Ejemplo de función para formatear ambos
  String _formatFechaHora(String dateString) {
    return BuenosAiresTime.formatDateTimeFromIso(dateString);
  }
}
