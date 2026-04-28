import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/services/session_audio_service.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/material.dart';
import 'package:all_food/src/features/auth/data/repositories/auth_repository.dart';
import '../../../../config/demo_accounts.dart';
import 'anonymous_client_page.dart';
import 'register_page.dart';
import 'package:all_food/src/shared/services/notificacion__service.dart';

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

  Future<void> _abrirSelectorIngresoRapido() async {
    if (_isLoading) return;

    final perfil = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppUi.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingreso rápido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Dueño',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('duenio'),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.white),
                  title: const Text(
                    'Supervisor',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('supervisor'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.restaurant_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Cocinero',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('cocinero'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.local_bar_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Cantinero',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('cantinero'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.room_service_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Metre',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('metre'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Cliente test',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('cliente'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.restaurant_menu_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Mozo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('mozo'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || perfil == null) return;

    // Completa las credenciales demo segun perfil seleccionado desde el FAB.
    if (perfil == 'duenio') {
      _completarIngresoRapidoDuenio();
    } else if (perfil == 'supervisor') {
      _emailController.text = DemoAccounts.supervisorEmail;
      _passwordController.text = DemoAccounts.supervisorPassword;
      setState(() {});
    } else if (perfil == 'cocinero') {
      _completarIngresoRapidoCocinero();
    } else if (perfil == 'cantinero') {
      _completarIngresoRapidoCantinero();
    } else if (perfil == 'metre') {
      _completarIngresoRapidoMetre();
    } else if (perfil == 'cliente') {
      _completarIngresoRapidoCliente();
    } else if (perfil == 'mozo') {
      _completarIngresoRapidoMozo();
    }
  }

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

      try {
        await NotificationService().init();
      } catch (_) {
        // Si falla no bloqueamos el login
      }
      await SessionAudioService.playLogin();
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

  void _completarIngresoRapidoMozo() {
    _emailController.text = DemoAccounts.mozoEmail;
    _passwordController.text = DemoAccounts.mozoPassword;
    setState(() {});
  }

  void _completarIngresoRapidoCantinero() {
    // Precarga credenciales de prueba para agilizar demos/manual testing.
    _emailController.text = DemoAccounts.cantineroEmail;
    _passwordController.text = DemoAccounts.cantineroPassword;
    setState(() {});
  }

  void _completarIngresoRapidoMetre() {
    // Precarga credenciales de prueba para agilizar demos/manual testing.
    _emailController.text = DemoAccounts.metreEmail;
    _passwordController.text = DemoAccounts.metrePassword;
    setState(() {});
  }

  void _completarIngresoRapidoCliente() {
    // Precarga credenciales de cliente registrado para validar el flujo de mesa.
    _emailController.text = DemoAccounts.clienteEmail;
    _passwordController.text = DemoAccounts.clientePassword;
    setState(() {});
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) {
      ErrorFeedback.vibrate();
    }

    // Centraliza mensajes de error/exito en un mismo estilo visual.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? AppUi.error : AppUi.exito,
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
              color: AppUi.exito,
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
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 52, 20, 2),
            child: Text(
              'Bienvenido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ArchivoBlack',
                fontSize: 42,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: AuthCard(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All Food',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ArchivoBlack',
                          fontSize: 38,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicio de sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      if (widget.initializationMessage != null) ...[
                        const SizedBox(height: 16),
                        MaterialBanner(
                          backgroundColor: const Color(0xFF8D2628),
                          content: Text(
                            widget.initializationMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          actions: const [SizedBox.shrink()],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: AppUi.acento,
                          foregroundColor: const Color(0xFF4A0E10),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white70,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Crear cuenta'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  final creado = await Navigator.of(
                                    context,
                                  ).push<bool>(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AnonymousClientPage(
                                            supabaseReady: widget.supabaseReady,
                                          ),
                                    ),
                                  );

                                  if (!context.mounted) return;
                                  if (creado != true) return;

                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/session',
                                    (route) => false,
                                  );
                                },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFFB45309),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Ingresar como cliente anónimo'),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: FloatingActionButton.extended(
                          onPressed:
                              _isLoading ? null : _abrirSelectorIngresoRapido,
                          icon: const Icon(Icons.flash_on),
                          extendedTextStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          label: const Text('Ingreso rápido'),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
