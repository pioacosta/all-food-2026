import 'package:flutter/material.dart';
import 'dart:io';

import 'package:all_food/src/features/productos/data/repositories/productos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';

class CrearProductoPage extends StatefulWidget {
  const CrearProductoPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<CrearProductoPage> createState() => _CrearProductoPageState();
}

class _CrearProductoPageState extends State<CrearProductoPage> {
  static const int _maxNombre = 22;
  static const int _maxDescripcion = 90;
  static const int _maxTiempo = 3;
  static const int _maxPrecio = 8;

  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _precioController = TextEditingController();

  final List<XFile?> _imagenes = [null, null, null];

  final ImagePicker _picker = ImagePicker();
  final _repository = ProductosRepository();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('C�f¡mara'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagen = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (imagen != null) {
                    setState(() => _imagenes[index] = imagen);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Galer�f­a'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagen = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (imagen != null) {
                    setState(() => _imagenes[index] = imagen);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _subirImagen(XFile imagen, String nombreArchivo) {
    return _repository.uploadProductImage(
      image: imagen,
      fileName: nombreArchivo,
    );
  }

  Future<String> _obtenerTipoProducto() async {
    final perfil = await _repository.getUserPerfil();

    if (perfil == null) {
      throw const ProductosFlowException(
        'No se pudo obtener el perfil del usuario.',
      );
    }

    if (perfil == 'cocinero') return 'plato';
    if (perfil == 'cantinero') return 'bebida';

    throw const ProductosFlowException(
      'Perfil no v�f¡lido para crear productos.',
    );
  }

  Future<void> _guardarProducto() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) return;

    if (_imagenes.contains(null)) {
      _mostrarMensaje('Debes cargar las 3 im�f¡genes', esError: true);
      return;
    }

    setState(() => _guardando = true);

    try {
      final tipo = await _obtenerTipoProducto();

      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      final tiempo = int.parse(_tiempoController.text.trim());
      final precio = double.parse(_precioController.text.trim());

      final userId = _repository.getCurrentUserIdOrThrow();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final base = '${userId}_$timestamp';

      final foto1 = await _subirImagen(_imagenes[0]!, '${base}_1.jpg');
      final foto2 = await _subirImagen(_imagenes[1]!, '${base}_2.jpg');
      final foto3 = await _subirImagen(_imagenes[2]!, '${base}_3.jpg');

      await _repository.createProduct(
        tipo: tipo,
        nombre: nombre,
        descripcion: descripcion,
        tiempo: tiempo,
        precio: precio,
        foto1: foto1,
        foto2: foto2,
        foto3: foto3,
      );

      if (!mounted) return;

      _mostrarMensaje(
        '${tipo == 'plato' ? 'Plato' : 'Bebida'} creado correctamente',
        esError: false,
      );

      _formKey.currentState!.reset();
      _nombreController.clear();
      _descripcionController.clear();
      _tiempoController.clear();
      _precioController.clear();

      setState(() {
        _imagenes[0] = null;
        _imagenes[1] = null;
        _imagenes[2] = null;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'Error al crear el producto.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFF5F0E0E);
    const cardBg = Color(0xFF8B1A1A);
    const fieldBg = Color(0xFFA52A2A);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Producto')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: pageBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: fieldBg,
                    labelStyle: const TextStyle(color: Color(0xFFFFDCDC)),
                    floatingLabelStyle: const TextStyle(color: Colors.white),
                    hintStyle: const TextStyle(color: Colors.white54),
                    counterStyle: const TextStyle(
                      color: Color(0xFFFFDCDC),
                      fontWeight: FontWeight.w700,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFFC2C2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.6,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF9D9D)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF9D9D),
                        width: 1.6,
                      ),
                    ),
                    errorStyle: const TextStyle(color: Color(0xFFFFCDCD)),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear Producto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ArchivoBlack',
                          fontSize: 34,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NOMBRE
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.white),
                        maxLength: _maxNombre,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxNombre),
                        ],
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // DESCRIPCI�f�?oN
                      TextFormField(
                        controller: _descripcionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        maxLength: _maxDescripcion,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxDescripcion),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Descripci�f³n',
                        ),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // TIEMPO
                      TextFormField(
                        controller: _tiempoController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        maxLength: _maxTiempo,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxTiempo),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tiempo (minutos)',
                        ),
                        validator:
                            (v) =>
                                int.tryParse(v ?? '') == null
                                    ? 'N�fºmero inv�f¡lido'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // PRECIO
                      TextFormField(
                        controller: _precioController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        maxLength: _maxPrecio,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxPrecio),
                        ],
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator:
                            (v) =>
                                double.tryParse(v ?? '') == null
                                    ? 'N�fºmero inv�f¡lido'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // IM�fGENES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (index) {
                          final img = _imagenes[index];
                          return GestureDetector(
                            onTap: () => _seleccionarImagen(index),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFC2C2),
                                ),
                              ),
                              child:
                                  img == null
                                      ? const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                      : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(img.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _guardando ? null : _guardarProducto,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white70,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child:
                            _guardando
                                ? const LogoSpinner(size: 20, strokeWidth: 2)
                                : const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
