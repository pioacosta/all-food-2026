import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:all_food/src/features/auth/data/repositories/auth_repository.dart';
import '../../../../config/demo_accounts.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.supabaseReady,
    this.initializationMessage,
    this.successMessage,
    this.errorMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;
  final String? successMessage;
  final String? errorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Clave del formulario para ejecutar validaciones.
  final _formKey = GlobalKey<FormState>();
  // Controladores para leer y limpiar campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Repositorio que abstrae llamadas a backend fuera de presentation.
  final _authRepository = AuthRepository();

  var _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Si venimos de logout exitoso, muestra una confirmacion visual al entrar.
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mostrarToastExito(widget.successMessage!);
      });
    }

    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mostrarMensaje(widget.errorMessage!, esError: true);
      });
    }
  }

  @override
  void dispose() {
    // Evita fugas de memoria al cerrar la pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    // Valida campos antes de pegarle al backend.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bloquea el intento si la app no pudo inicializar Supabase.
    if (!widget.supabaseReady) {
      _mostrarMensaje(
        'No hay conexión a Supabase. Revisa las variables de entorno.',
        esError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // La UI delega el login al repositorio y solo maneja estados visuales.
      final response = await _authRepository.loginWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user == null) {
        _mostrarMensaje('No fue posible iniciar sesión.', esError: true);
        return;
      }
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'Ocurrió un error inesperado al ingresar.',
        ),
        esError: true,
      );
    } finally {
      // Siempre re-habilita botones al terminar.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _completarIngresoRapidoDuenio() {
    // Precarga credenciales de prueba para agilizar demos/manual testing.
    _emailController.text = DemoAccounts.duenioEmail;
    _passwordController.text = DemoAccounts.duenioPassword;
    setState(() {});
  }
  void _completarIngresoRapidoCocinero() {
    // Precarga credenciales de prueba para agilizar demos/manual testing.
    _emailController.text = DemoAccounts.cocineroEmail;
    _passwordController.text = DemoAccounts.cocineroPassword;
    setState(() {});
  }
  void _completarIngresoRapidoCantinero() {
    // Precarga credenciales de prueba para agilizar demos/manual testing.
    _emailController.text = DemoAccounts.cantineroEmail;
    _passwordController.text = DemoAccounts.cantineroPassword;
    setState(() {});
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    // Centraliza mensajes de error/exito en un mismo estilo visual.
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

  void _mostrarToastExito(String mensaje) {
    // Toast custom flotante para confirmaciones positivas (evita dialogos default).
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 0,
          backgroundColor: Colors.transparent,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Center(
        child: AuthCard(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'All Food',
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
                    'Inicio de sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (widget.initializationMessage != null) ...[
                    const SizedBox(height: 16),
                    MaterialBanner(
                      backgroundColor: const Color(0xFF8D2628),
                      content: Text(
                        widget.initializationMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Debes ingresar un correo electrónico.';
                      }
                      final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!pattern.hasMatch(email)) {
                        return 'Correo electrónico inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) {
                        return 'Debes ingresar una contraseña.';
                      }
                      if (password.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _ingresar,
                    child:
                        _isLoading
                            // Indicador visual en esperas de red.
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: LogoSpinner(size: 20, strokeWidth: 2),
                            )
                            : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              // Navega al registro para crear nueva cuenta.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => RegisterPage(
                                        supabaseReady: widget.supabaseReady,
                                      ),
                                ),
                              );
                            },
                    child: const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white38)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'INGRESOS RAPIDOS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Tooltip(
                        message: 'Completar ingreso de duenio',
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : _completarIngresoRapidoDuenio,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'Completar ingreso de cocinero',
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : _completarIngresoRapidoCocinero,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.restaurant_outlined),
                        ),
                      ),
                      Tooltip(
                        message: 'Completar ingreso de cantinero',
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : _completarIngresoRapidoCantinero,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.restaurant_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
