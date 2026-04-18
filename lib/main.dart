import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:all_food/firebase_options.dart';

import 'src/all_food_app.dart';
import 'src/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase primero, antes de todo
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  var supabaseReady = false;
  String? initializationMessage;

  if (SupabaseConfig.isConfigured) {
    try {
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

  runApp(
    AllFoodApp(
      supabaseReady: supabaseReady,
      initializationMessage: initializationMessage,
    ),
  );
}