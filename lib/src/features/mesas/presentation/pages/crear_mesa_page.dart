import 'package:flutter/material.dart';
import 'dart:io';

import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CrearMesaPage extends StatefulWidget {
  const CrearMesaPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<CrearMesaPage> createState() => _CrearMesaPageState();
}

class _CrearMesaPageState extends State<CrearMesaPage> {
  final _numeroController = TextEditingController();
  final _comensalesController = TextEditingController();
  final _picker = ImagePicker();
  final _repository = MesasRepository();

  String? _tipoSeleccionado;
  File? _foto;

  bool _validandoAcceso = true;
  bool _puedeCrearMesas = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _comensalesController.dispose();
    super.dispose();
  }

  Future<void> _cargarPermisos() async {
    if (!widget.supabaseReady) {
      setState(() {
        _validandoAcceso = false;
        _puedeCrearMesas = false;
      });
      return;
    }

    try {
      final autorizado = await _repository.canCurrentUserCreateTables();
      if (!mounted) return;

      setState(() {
        _validandoAcceso = false;
        _puedeCrearMesas = autorizado;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validandoAcceso = false;
        _puedeCrearMesas = false;
      });
    }
  }

  Future<void> _tomarFotoMesa() async {
    final tomada = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (tomada == null) return;

    setState(() {
      _foto = File(tomada.path);
    });
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

  Future<void> _crearMesa() async {
    if (_guardando) return;

    final numeroText = _numeroController.text.trim();
    final comensalesText = _comensalesController.text.trim();

    if (numeroText.isEmpty ||
        comensalesText.isEmpty ||
        _tipoSeleccionado == null ||
        _foto == null) {
      _mostrarMensaje('TODOS los campos son obligatorios.', esError: true);
      return;
    }

    final numero = int.tryParse(numeroText);
    final comensales = int.tryParse(comensalesText);

    if (numero == null || numero <= 0) {
      _mostrarMensaje(
        'El número de mesa debe ser un entero positivo.',
        esError: true,
      );
      return;
    }

    if (comensales == null || comensales <= 0) {
      _mostrarMensaje(
        'La cantidad de comensales debe ser un entero positivo.',
        esError: true,
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final existe = await _repository.tableNumberExists(numero);
      if (existe) {
        _mostrarMensaje('Ya existe una mesa con ese número.', esError: true);
        return;
      }

      final fotoUrl = await _repository.uploadTablePhoto(_foto!);

      await _repository.createTable(
        numeroMesa: numero,
        cantidadComensales: comensales,
        tipoMesa: _tipoSeleccionado!,
        fotoUrl: fotoUrl,
      );

      if (!mounted) return;

      _mostrarMensaje('Mesa creada correctamente.', esError: false);

      _numeroController.clear();
      _comensalesController.clear();
      setState(() {
        _tipoSeleccionado = null;
        _foto = null;
      });
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo crear la mesa.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_validandoAcceso) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    if (!_puedeCrearMesas) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear mesa')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado. Esta funcionalidad está disponible solo para dueño y supervisor habilitados.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crear mesa')),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 132,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1A1A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nueva mesa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ArchivoBlack',
                          fontSize: 34,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa todos los campos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numeroController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Número de mesa',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _comensalesController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Cantidad de comensales',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _tipoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de mesa',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: const Color(0xFF7A2021),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'vip', child: Text('VIP')),
                          DropdownMenuItem(
                            value: 'estandar',
                            child: Text('Estándar'),
                          ),
                          DropdownMenuItem(
                            value: 'movilidad_reducida',
                            child: Text('Movilidad reducida'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoSeleccionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_foto == null)
                        ElevatedButton.icon(
                          onPressed: _tomarFotoMesa,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar foto de mesa'),
                        )
                      else
                        Center(
                          child: InkWell(
                            onTap: _tomarFotoMesa,
                            borderRadius: BorderRadius.circular(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _foto!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _guardando ? null : _crearMesa,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child:
                            _guardando
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: LogoSpinner(size: 20, strokeWidth: 2),
                                )
                                : const Text('Crear mesa'),
                      ),
                    ],
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
