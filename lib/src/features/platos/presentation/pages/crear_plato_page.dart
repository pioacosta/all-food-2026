import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';

class CrearPlatoPage extends StatefulWidget {
  const CrearPlatoPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<CrearPlatoPage> createState() => _CrearPlatoPageState();
}

class _CrearPlatoPageState extends State<CrearPlatoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _precioController = TextEditingController();

  final List<XFile?> _imagenes = [null, null, null];

  final ImagePicker _picker = ImagePicker();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // 📸 Selección cámara / galería
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

  // ☁️ Subir imagen a Supabase Storage
  Future<String> _subirImagen(XFile imagen, String nombreArchivo) async {
    final bytes = await imagen.readAsBytes();

    final path = 'platos/$nombreArchivo';

    await Supabase.instance.client.storage
        .from('productos')
        .uploadBinary(path, bytes);

    final url = Supabase.instance.client.storage
        .from('productos')
        .getPublicUrl(path);

    return url;
  }

  // 💾 Guardar plato
  Future<void> _guardarPlato() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) return;

    if (_imagenes.contains(null)) {
      _mostrarMensaje('Debes cargar las 3 imágenes', esError: true);
      return;
    }

    setState(() => _guardando = true);

    try {
      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      final tiempo = int.parse(_tiempoController.text);
      final precio = double.parse(_precioController.text);

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final base = '${userId}_$timestamp';

      // 📸 subir imágenes
      final foto1 = await _subirImagen(_imagenes[0]!, '${base}_1.jpg');
      final foto2 = await _subirImagen(_imagenes[1]!, '${base}_2.jpg');
      final foto3 = await _subirImagen(_imagenes[2]!, '${base}_3.jpg');

      // 💾 guardar en DB
      await Supabase.instance.client.from('productos').insert({
        'tipo': 'plato',
        'nombre': nombre,
        'descripcion': descripcion,
        'tiempo_elaboracion_min': tiempo,
        'precio': precio,
        'foto_1_url': foto1,
        'foto_2_url': foto2,
        'foto_3_url': foto3,
        'habilitado': true,
      });

      _mostrarMensaje('Plato creado correctamente', esError: false);

      // limpiar form
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
    } catch (e) {
      _mostrarMensaje('Error al crear el plato: $e', esError: true);
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
          content: Text(mensaje),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Plato')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF6B1010), // fondo rojo oscuro
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A), // card rojo medio
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TÍTULO
                    const Text(
                      'Crear Plato',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ArchivoBlack',
                        fontSize: 34,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Completá los datos del plato',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),

                    // NOMBRE
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nombre del plato',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF9B2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // DESCRIPCIÓN
                    TextFormField(
                      controller: _descripcionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF9B2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // TIEMPO
                    TextFormField(
                      controller: _tiempoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tiempo de elaboración (min)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF9B2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El tiempo es obligatorio';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // PRECIO
                    TextFormField(
                      controller: _precioController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF9B2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El precio es obligatorio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // FOTOS — label
                    const Text(
                      'Fotos del plato',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),

                    // FOTOS — 3 slots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (index) {
                        final imagen = _imagenes[index];
                        return GestureDetector(
                          onTap: () => _seleccionarImagen(index),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B2A2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child:
                                imagen == null
                                    ? const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Agregar',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    )
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imagen.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // BOTÓN GUARDAR
                    FilledButton(
                      onPressed: _guardando ? null : _guardarPlato,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B1010),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          _guardando
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: LogoSpinner(size: 20, strokeWidth: 2),
                              )
                              : const Text(
                                'Guardar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
