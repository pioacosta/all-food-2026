import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class EncuestaClientePage extends StatefulWidget {
  const EncuestaClientePage({required this.pedidoId, super.key});

  final String pedidoId;

  @override
  State<EncuestaClientePage> createState() => _EncuestaClientePageState();
}

class _EncuestaClientePageState extends State<EncuestaClientePage> {
  final _repo = PedidosRepository();
  final _comentarioController = TextEditingController();

  int _comida = 4;
  int _servicio = 4;
  bool _recomendaria = true;
  bool _guardando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _repo.guardarEncuesta(
        pedidoId: widget.pedidoId,
        puntuacionComida: _comida,
        puntuacionServicio: _servicio,
        recomendaria: _recomendaria,
        comentario: _comentarioController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Encuesta guardada correctamente.'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMapper.toUserMessage(
                error,
                fallbackMessage: 'No se pudo guardar la encuesta.',
              ),
            ),
            backgroundColor: const Color(0xFF992E2E),
          ),
        );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encuesta de satisfacción')),
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
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              55,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PreguntaCard(
                  titulo: '¿Cómo evaluas la comida?',
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFFD27A),
                      inactiveTrackColor: Colors.white30,
                      thumbColor: const Color(0xFFFFE2A8),
                      overlayColor: const Color(0x33FFE2A8),
                      valueIndicatorColor: const Color(0xFFFFE2A8),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Color(0xFF4A0E10),
                        fontWeight: FontWeight.w700,
                        fontSize: 90
                      ),
                    ),
                    child: Slider(
                      value: _comida.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_comida',
                      onChanged: (v) => setState(() => _comida = v.round()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PreguntaCard(
                  titulo: '¿Cómo evaluas la atención?',
                  child: DropdownButtonFormField<int>(
                    value: _servicio,
                    dropdownColor: const Color(0xFF8D2628),
                    iconEnabledColor: const Color(0xFFFFE2A8),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFE2A8),
                          width: 1.4,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 - Muy mala')),
                      DropdownMenuItem(value: 2, child: Text('2 - Mala')),
                      DropdownMenuItem(value: 3, child: Text('3 - Regular')),
                      DropdownMenuItem(value: 4, child: Text('4 - Buena')),
                      DropdownMenuItem(value: 5, child: Text('5 - Excelente')),
                    ],
                    onChanged: (v) => setState(() => _servicio = v ?? 4),
                  ),
                ),
                const SizedBox(height: 16),
                _PreguntaCard(
                  titulo: '¿Recomendarías All Food?',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFFE2A8),
                    activeTrackColor: const Color(0xFF2D6A4F),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                    value: _recomendaria,
                    onChanged: (v) => setState(() => _recomendaria = v),
                    title: Text(
                      _recomendaria
                          ? 'Sí, lo recomendaría'
                          : 'No lo recomendaría',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PreguntaCard(
                  titulo: 'Comentario adicional',
                  child: TextField(
                    controller: _comentarioController,
                    maxLines: 8,
                    minLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu opinión...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFE2A8),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _guardando ? null : _guardar,
                    child:
                        _guardando
                            ? const LogoSpinner(size: 18, strokeWidth: 2)
                            : const Text('Guardar encuesta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreguntaCard extends StatelessWidget {
  const _PreguntaCard({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFFFFE2A8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
