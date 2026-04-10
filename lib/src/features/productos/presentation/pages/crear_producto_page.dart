import 'dart:io';

import 'package:all_food/src/features/productos/data/repositories/productos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';

class CrearProductoPage extends StatefulWidget {
  const CrearProductoPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<CrearProductoPage> createState() => _CrearProductoPageState();
}

class _CrearProductoPageState extends State<CrearProductoPage> {
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
                title: const Text('Cámara'),
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
                title: const Text('Galería'),
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
      'Perfil no válido para crear productos.',
    );
  }

  Future<void> _guardarProducto() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) return;

    if (_imagenes.contains(null)) {
      _mostrarMensaje('Debes cargar las 3 imágenes', esError: true);
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
      appBar: AppBar(title: const Text('Crear Producto')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF6B1010),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A),
                borderRadius: BorderRadius.circular(16),
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
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // DESCRIPCIÓN
                    TextFormField(
                      controller: _descripcionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // TIEMPO
                    TextFormField(
                      controller: _tiempoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Tiempo (min)'),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null
                              ? 'Número inválido'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // PRECIO
                    TextFormField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Precio'),
                      validator: (v) =>
                          double.tryParse(v ?? '') == null
                              ? 'Número inválido'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // IMÁGENES
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
                            ),
                            child: img == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
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
                      child: _guardando
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
    );
  }
}