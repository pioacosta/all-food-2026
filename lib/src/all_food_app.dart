import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/splash/splash_page.dart';

class AllFoodApp extends StatelessWidget {
  const AllFoodApp({
    required this.supabaseReady,
    this.initializationMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;

  @override
  Widget build(BuildContext context) {
    // Esquema de color base para mantener coherencia visual.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'All Food',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0A1931),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF102A5C),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
      ),
      // Punto de entrada real: decide si mostrar login o home segun sesion.
      home: SplashPage(
        supabaseReady: supabaseReady,
        // initializationMessage: initializationMessage,
      ),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({
    required this.supabaseReady,
    this.initializationMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;

  @override
  Widget build(BuildContext context) {
    // Si Supabase no esta listo, solo permite ver la pantalla de login con aviso.
    if (!supabaseReady) {
      return LoginPage(
        supabaseReady: supabaseReady,
        initializationMessage: initializationMessage,
      );
    }

    // Escucha cambios de autenticacion en tiempo real.
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      // Toma la sesion actual al inicio para evitar parpadeos de pantalla.
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // Sin sesion activa: se mantiene en login.
        if (session == null) {
          return LoginPage(
            supabaseReady: supabaseReady,
            initializationMessage: initializationMessage,
          );
        }

        // Con sesion valida: navega al home.
        return HomePage(supabaseReady: supabaseReady);
      },
    );
  }
}
