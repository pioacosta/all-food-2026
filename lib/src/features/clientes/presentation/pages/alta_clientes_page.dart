import 'package:flutter/material.dart';
import 'dart:io';

import 'package:all_food/src/features/clientes/data/repository/cliente_repository.dart';
import 'package:all_food/src/shared/dni_qr/dni_qr_data.dart';
import 'package:all_food/src/shared/dni_qr/dni_qr_scanner_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AltaClientePage extends StatefulWidget {
  const AltaClientePage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<AltaClientePage> createState() => _AltaClientePageState();
}

class _AltaClientePageState extends State<AltaClientePage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final _picker = ImagePicker();
  final _clienteRepository = ClientesRepository();

  File? _foto;
  bool _mostrarPassword = false;
  bool _guardando = false;
  bool _validandoAcceso = true;
  bool _puedeCrearClientes = false;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarPermisos() async {
    if (!widget.supabaseReady) {
      setState(() {
        _validandoAcceso = false;
        _puedeCrearClientes = false;
      });
      return;
    }

    try {
      final autorizado = await _clienteRepository.canCurrentUserCreateClients();
      if (!mounted) return;
      setState(() {
        _validandoAcceso = false;
        _puedeCrearClientes = autorizado;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validandoAcceso = false;
        _puedeCrearClientes = false;
      });
    }
  }

  Future<void> _tomarFoto() async {
    final tomada = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      preferredCameraDevice: CameraDevice.front,
    );
    if (tomada == null) return;
    setState(() => _foto = File(tomada.path));
  }

  Future<void> _crearCliente() async {
    if (!_puedeCrearClientes) {
      _mostrarMensaje(
        'Solo el metre habilitado puede dar de alta clientes.',
        esError: true,
      );
      return;
    }

    final faltanObligatorios =
        _nombreController.text.trim().isEmpty ||
        _apellidoController.text.trim().isEmpty ||
        _dniController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _foto == null;

    if (faltanObligatorios) {
      _mostrarMensaje('Todos los campos son obligatorios.', esError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final fotoUrl = await _clienteRepository.uploadClientPhoto(_foto!);

      await _clienteRepository.createClient(
        nombres: _nombreController.text.trim(),
        apellidos: _apellidoController.text.trim(),
        dni: _dniController.text.trim(),
        correo: _correoController.text.trim().toLowerCase(),
        password: _passwordController.text,
        fotoUrl: fotoUrl,
      );

      try {
        await Supabase.instance.client.functions.invoke(
          'notificar-cliente-pendiente',
          body: {
            'clienteNombre':
                '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
          },
        );
      } catch (_) {
        // Si falla la notificaciÃƒÂ³n no bloqueamos el flujo
      }

      if (!mounted) return;

      _mostrarMensaje('Cliente creado correctamente.', esError: false);

      _formKey.currentState?.reset();
      _nombreController.clear();
      _apellidoController.clear();
      _dniController.clear();
      _correoController.clear();
      _passwordController.clear();
      setState(() => _foto = null);
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage:
              'OcurriÃƒÂ³ un error inesperado al crear el cliente.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _abrirLectorQrDni() async {
    final resultado = await Navigator.of(context).push<DniQrData>(
      MaterialPageRoute(builder: (_) => const DniQrScannerPage()),
    );

    if (!mounted || resultado == null) return;

    _apellidoController.text = resultado.apellido ?? '';
    _nombreController.text = resultado.nombre ?? '';
    _dniController.text = resultado.dni ?? '';

    _mostrarMensaje('QR aplicado correctamente', esError: false);
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) {
      ErrorFeedback.vibrate();
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            maxLines: esError ? 4 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          duration: Duration(seconds: esError ? 8 : 4),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  String? _validarNombreOApellido(String? value, String etiqueta) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length < 2 || text.length > 60) {
      return '$etiqueta debe tener entre 2 y 60 caracteres.';
    }
    final soloLetras = RegExp(
      r'^[A-Za-zÃƒÂÃƒâ€°ÃƒÂÃƒâ€œÃƒÅ¡ÃƒÂ¡ÃƒÂ©ÃƒÂ­ÃƒÂ³ÃƒÂºÃƒâ€˜ÃƒÂ±ÃƒÅ“ÃƒÂ¼ ]+$',
    );
    if (!soloLetras.hasMatch(text)) {
      return '$etiqueta solo puede contener letras y espacios.';
    }
    return null;
  }

  String? _validarDni(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d{7,8}$').hasMatch(text)) {
      return 'El DNI debe tener 7 u 8 dÃƒÂ­gitos numÃƒÂ©ricos.';
    }
    return null;
  }

  String? _validarCorreo(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Correo electrÃƒÂ³nico invÃƒÂ¡lido.';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return null;
    if (text.length < 8 || text.length > 32) {
      return 'La contraseÃƒÂ±a debe tener entre 8 y 32 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return 'Debe contener al menos una letra mayÃƒÂºscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return 'Debe contener al menos una letra minÃƒÂºscula.';
    }
    if (!RegExp(r'\d').hasMatch(text)) {
      return 'Debe contener al menos un nÃƒÂºmero.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(text)) {
      return 'Debe contener al menos un carÃƒÂ¡cter especial.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_validandoAcceso) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    if (!_puedeCrearClientes) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta de clientes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado. Esta funcionalidad estÃƒÂ¡ disponible solo para el metre habilitado.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Alta de clientes')),
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
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  labelStyle: TextStyle(color: Colors.white70),
                  floatingLabelStyle: TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white54),
                  errorMaxLines: 1,
                  errorStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Header Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    const Text(
                      'Nuevo cliente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ArchivoBlack',
                        fontSize: 32,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CompletÃƒÂ¡ todos los campos',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Nombre Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre/s',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _validarNombreOApellido(v, 'el nombre'),
                    ),
                    const SizedBox(height: 12),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Apellido Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    TextFormField(
                      controller: _apellidoController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido/s',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) => _validarNombreOApellido(v, 'el apellido'),
                    ),
                    const SizedBox(height: 12),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ DNI CON QR INTEGRADO Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    TextFormField(
                      controller: _dniController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ], // Mantenemos tus formatters
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'DNI',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        // AquÃƒÂ­ integramos el botÃƒÂ³n de QR que tenÃƒÂ­as afuera
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                            ),
                            onPressed: _abrirLectorQrDni,
                          ),
                        ),
                      ),
                      validator: _validarDni,
                    ),
                    const SizedBox(height: 12),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Correo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    TextFormField(
                      controller: _correoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrÃƒÂ³nico',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validarCorreo,
                    ),
                    const SizedBox(height: 12),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Password Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: !_mostrarPassword,
                      decoration: InputDecoration(
                        labelText: 'ContraseÃƒÂ±a',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed:
                              () => setState(
                                () => _mostrarPassword = !_mostrarPassword,
                              ),
                          icon: Icon(
                            _mostrarPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      validator: _validarPassword,
                    ),
                    const SizedBox(height: 20),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Foto Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    if (_foto == null) ...[
                      ElevatedButton.icon(
                        onPressed: _tomarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar foto personal'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Foto obligatoria. Se toma con cÃƒÂ¡mara frontal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ] else ...[
                      Center(
                        child: InkWell(
                          onTap: _tomarFoto,
                          borderRadius: BorderRadius.circular(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _foto!,
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'TocÃƒÂ¡ la foto para cambiarla.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ BotÃƒÂ³n crear Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    FilledButton(
                      onPressed: _guardando ? null : _crearCliente,
                      child:
                          _guardando
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: LogoSpinner(size: 20, strokeWidth: 2),
                              )
                              : const Text('Crear cliente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
