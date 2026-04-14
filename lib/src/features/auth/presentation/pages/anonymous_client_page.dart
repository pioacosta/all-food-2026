import 'dart:io';

import 'package:all_food/src/features/auth/data/repositories/auth_repository.dart';
import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AnonymousClientPage extends StatefulWidget {
  const AnonymousClientPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<AnonymousClientPage> createState() => _AnonymousClientPageState();
}

class _AnonymousClientPageState extends State<AnonymousClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _authRepository = AuthRepository();

  File? _foto;
  var _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _foto = File(picked.path);
    });
  }

  Future<void> _ingresarComoAnonimo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!widget.supabaseReady) {
      _mostrarMensaje(
        'No hay conexion a Supabase. Revisa las variables de entorno.',
        esError: true,
      );
      return;
    }

    if (_foto == null) {
      _mostrarMensaje('Debes tomar una foto.', esError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.registerAnonymousClient(
        nombres: _nombreController.text.trim(),
        foto: _foto!,
      );

      if (!mounted) return;

      _mostrarMensaje('Cliente anonimo creado y habilitado.', esError: false);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo crear el cliente anonimo.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    return AuthBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 75, 20, 12),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 148,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 6),
                      Card(
                        color: const Color(0xFF8D2628),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Ingreso anonimo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'ArchivoBlack',
                                    fontSize: 28,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ingresa tu nombre y toma una foto para continuar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nombreController,
                                  style: const TextStyle(color: Colors.white),
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return 'Debes ingresar un nombre.';
                                    }
                                    if (text.length < 2) {
                                      return 'Nombre invalido.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                if (_foto == null)
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _tomarFoto,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Tomar foto'),
                                  )
                                else
                                  Column(
                                    children: [
                                      InkWell(
                                        onTap: _isLoading ? null : _tomarFoto,
                                        borderRadius: BorderRadius.circular(10),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            _foto!,
                                            height: 140,
                                            width: 140,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Toca la foto para cambiarla',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed:
                                      _isLoading ? null : _ingresarComoAnonimo,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    textStyle: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: LogoSpinner(
                                              size: 20,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Continuar como anonimo',
                                          ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white70,
                                      width: 1.2,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Volver al ingreso'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
