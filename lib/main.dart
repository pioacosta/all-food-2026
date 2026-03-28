import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/all_food_app.dart';
import 'src/config/supabase_config.dart';

Future<void> main() async {
  // Necesario para ejecutar codigo async antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Carga variables del archivo .env para desarrollo local.
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Si no existe .env en el entorno de ejecucion, se usa fallback.
  }

  var supabaseReady = false;
  String? initializationMessage;

  if (SupabaseConfig.isConfigured) {
    try {
      // Inicializa el cliente global de Supabase una sola vez al arrancar.
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      supabaseReady = true;
    } catch (error) {
      initializationMessage = 'No se pudo iniciar Supabase: $error';
    }
  } else {
    initializationMessage =
        'Falta configurar SUPABASE_URL y SUPABASE_ANON_KEY en .env o con --dart-define.';
  }

  // Inyecta el estado de inicializacion para que la UI muestre mensajes claros.
  runApp(
    AllFoodApp(
      supabaseReady: supabaseReady,
      initializationMessage: initializationMessage,
    ),
  );
}
