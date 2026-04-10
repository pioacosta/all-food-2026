import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:all_food/src/features/staff/data/repositories/staff_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import '../../../../shared/widgets/logo_spinner.dart';

// Pantalla para alta de personal con validaciones y carga de foto.
class AltaEmpleadoPage extends StatefulWidget {
  const AltaEmpleadoPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<AltaEmpleadoPage> createState() => _AltaEmpleadoPageState();
}

class _AltaEmpleadoPageState extends State<AltaEmpleadoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _cuilController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final _picker = ImagePicker();
  final _staffRepository = StaffRepository();

  File? _foto;
  String? _perfilSeleccionado;
  bool _guardando = false;
  bool _validandoAcceso = true;
  bool _puedeCrearEmpleados = false;

  @override
  void initState() {
    super.initState();
    // Valida permisos al abrir para bloquear acceso no autorizado.
    _cargarPermisos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _cuilController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarPermisos() async {
    if (!widget.supabaseReady) {
      setState(() {
        _validandoAcceso = false;
        _puedeCrearEmpleados = false;
      });
      return;
    }

    try {
      final autorizado = await _staffRepository.canCurrentUserCreateEmployees();

      if (!mounted) return;

      setState(() {
        _validandoAcceso = false;
        _puedeCrearEmpleados = autorizado;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validandoAcceso = false;
        _puedeCrearEmpleados = false;
      });
    }
  }

  // Toma foto personal obligatoria usando camara frontal.
  Future<void> _tomarFoto() async {
    final tomada = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      preferredCameraDevice: CameraDevice.front,
    );

    if (tomada == null) return;

    setState(() {
      _foto = File(tomada.path);
    });
  }

  // Abre scanner QR/PDF417 para autocompletar datos del DNI.
  Future<void> _abrirLectorQrDni() async {
    final resultado = await Navigator.of(context).push<_DniQrData>(
      MaterialPageRoute(builder: (_) => const _DniQrScannerPage()),
    );

    if (!mounted || resultado == null) return;

    if (resultado.apellido != null && resultado.apellido!.trim().isNotEmpty) {
      _apellidoController.text = resultado.apellido!.trim();
    }

    if (resultado.nombre != null && resultado.nombre!.trim().isNotEmpty) {
      _nombreController.text = resultado.nombre!.trim();
    }

    if (resultado.dni != null && resultado.dni!.trim().isNotEmpty) {
      _dniController.text = resultado.dni!.trim();
    }

    if (resultado.cuil != null && resultado.cuil!.trim().isNotEmpty) {
      _cuilController.text = resultado.cuil!.trim();
    }

    _mostrarMensaje(
      'Lectura de QR de DNI verificada y aplicada.',
      esError: false,
    );
  }

  // Delega upload de imagen al repositorio de staff.
  Future<String> _subirFotoEmpleado(File foto) async {
    return _staffRepository.uploadStaffPhoto(foto);
  }

  // Ejecuta alta de empleado validando permisos y datos requeridos.
  Future<void> _crearEmpleado() async {
    if (!_puedeCrearEmpleados) {
      _mostrarMensaje(
        'Solo dueño o supervisor habilitado pueden crear empleados.',
        esError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_perfilSeleccionado == null) {
      _mostrarMensaje(
        'Debes seleccionar un perfil para el empleado.',
        esError: true,
      );
      return;
    }

    if (_foto == null) {
      _mostrarMensaje(
        'Debes tomar una foto personal del empleado.',
        esError: true,
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final fotoUrl = await _subirFotoEmpleado(_foto!);

      await _staffRepository.createEmployee(
        nombres: _nombreController.text.trim(),
        apellidos: _apellidoController.text.trim(),
        dni: _dniController.text.trim(),
        cuil: _cuilController.text.trim(),
        correo: _correoController.text.trim().toLowerCase(),
        password: _passwordController.text,
        perfil: _perfilSeleccionado!,
        fotoUrl: fotoUrl,
      );

      if (!mounted) return;

      _mostrarMensaje('Empleado creado correctamente.', esError: false);

      _formKey.currentState?.reset();
      _nombreController.clear();
      _apellidoController.clear();
      _dniController.clear();
      _cuilController.clear();
      _correoController.clear();
      _passwordController.clear();

      setState(() {
        _perfilSeleccionado = null;
        _foto = null;
      });
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'Ocurrió un error inesperado al crear el empleado.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
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
          action:
              esError
                  ? SnackBarAction(
                    label: 'Ver detalle',
                    textColor: Colors.white,
                    onPressed: () => _mostrarDialogoError(mensaje),
                  )
                  : null,
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error al crear empleado'),
          content: SingleChildScrollView(child: SelectableText(mensaje)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String? _validarNombreOApellido(String? value, String etiqueta) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Debes ingresar $etiqueta.';
    }

    if (text.length < 2 || text.length > 60) {
      return '$etiqueta debe tener entre 2 y 60 caracteres.';
    }

    final soloLetras = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]+$');
    if (!soloLetras.hasMatch(text)) {
      return '$etiqueta solo puede contener letras y espacios.';
    }

    return null;
  }

  String? _validarDni(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Debes ingresar el DNI.';
    }

    if (!RegExp(r'^\d{7,8}$').hasMatch(text)) {
      return 'El DNI debe tener 7 u 8 dígitos numéricos.';
    }

    return null;
  }

  String? _validarCuil(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Debes ingresar el CUIL.';
    }

    if (!RegExp(r'^\d{11}$').hasMatch(text)) {
      return 'El CUIL debe tener exactamente 11 dígitos.';
    }

    if (!_esCuilValido(text)) {
      return 'El CUIL ingresado no es válido.';
    }

    return null;
  }

  bool _esCuilValido(String cuil) {
    final factores = <int>[5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var suma = 0;

    for (var i = 0; i < factores.length; i++) {
      suma += int.parse(cuil[i]) * factores[i];
    }

    final modulo = suma % 11;
    var verificador = 11 - modulo;

    if (verificador == 11) verificador = 0;
    if (verificador == 10) verificador = 9;

    return verificador == int.parse(cuil[10]);
  }

  String? _validarCorreo(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Debes ingresar el correo electrónico.';
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return 'Correo electrónico inválido.';
    }

    return null;
  }

  String? _validarPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Debes ingresar una contraseña.';
    }

    if (text.length < 8 || text.length > 32) {
      return 'La contraseña debe tener entre 8 y 32 caracteres.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return 'Debe contener al menos una letra mayúscula.';
    }

    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return 'Debe contener al menos una letra minúscula.';
    }

    if (!RegExp(r'\d').hasMatch(text)) {
      return 'Debe contener al menos un número.';
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(text)) {
      return 'Debe contener al menos un carácter especial.';
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

    if (!_puedeCrearEmpleados) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta de empleados')),
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
      appBar: AppBar(title: const Text('Alta de empleados')),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nuevo empleado',
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
                    'Completa todos los campos y validaciones obligatorias',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _abrirLectorQrDni,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Leer QR de DNI'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre/s',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) => _validarNombreOApellido(value, 'el nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apellidoController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Apellido/s',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            _validarNombreOApellido(value, 'el apellido'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dniController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarDni,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cuilController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'CUIL (11 dígitos)',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarCuil,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _correoController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarCorreo,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarPassword,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _perfilSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Perfil / rol',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: const Color(0xFF7A2021),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(
                        value: 'cocinero',
                        child: Text('Cocinero'),
                      ),
                      DropdownMenuItem(
                        value: 'cantinero',
                        child: Text('Cantinero'),
                      ),
                      DropdownMenuItem(value: 'metre', child: Text('Metre')),
                      DropdownMenuItem(value: 'mozo', child: Text('Mozo')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _perfilSeleccionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debes seleccionar un perfil/rol.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto personal'),
                  ),
                  const SizedBox(height: 8),
                  if (_foto != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _foto!,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Foto obligatoria. Se toma con cámara (sin galería).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _guardando ? null : _crearEmpleado,
                    child:
                        _guardando
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: LogoSpinner(size: 20, strokeWidth: 2),
                            )
                            : const Text('Crear empleado'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DniQrScannerPage extends StatefulWidget {
  const _DniQrScannerPage();

  @override
  State<_DniQrScannerPage> createState() => _DniQrScannerPageState();
}

class _DniQrScannerPageState extends State<_DniQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.pdf417],
  );

  bool _leyendo = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_leyendo) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue?.trim();

    if (raw == null || raw.isEmpty) return;

    _leyendo = true;

    final data = _parsearQrDni(raw);

    if (data.dni == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'QR leído, pero no se pudo identificar un DNI válido.',
            ),
            backgroundColor: Color(0xFF992E2E),
          ),
        );
      _leyendo = false;
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR del DNI')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 280,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(
              'Apunta al QR/PDF417 del DNI. Se completarán automáticamente los campos disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DniQrData {
  const _DniQrData({this.nombre, this.apellido, this.dni, this.cuil});

  final String? nombre;
  final String? apellido;
  final String? dni;
  final String? cuil;
}

_DniQrData _parsearQrDni(String raw) {
  final limpio = raw.replaceAll('\u0000', '').replaceAll('"', '').trim();

  final separadorPrincipal =
      limpio.contains('@') ? '@' : (limpio.contains('|') ? '|' : '\n');

  final tokens =
      limpio
          .split(separadorPrincipal)
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

  String? apellido;
  String? nombre;
  String? dni;
  String? cuil;

  for (final token in tokens) {
    if (dni == null && RegExp(r'^\d{7,8}$').hasMatch(token)) {
      dni = token;
      continue;
    }

    if (cuil == null && RegExp(r'^\d{11}$').hasMatch(token)) {
      cuil = token;
      continue;
    }
  }

  final letras =
      tokens
          .where((t) => RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]{2,}$').hasMatch(t))
          .toList();

  if (letras.isNotEmpty) {
    apellido = letras.first;
  }

  if (letras.length > 1) {
    nombre = letras[1];
  }

  return _DniQrData(nombre: nombre, apellido: apellido, dni: dni, cuil: cuil);
}
