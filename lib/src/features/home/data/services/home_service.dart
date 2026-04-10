import 'package:supabase_flutter/supabase_flutter.dart';

// Capa de acceso a datos de Home contra Supabase.
class HomeService {
  HomeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> getProfileById(String userId) {
    return _client.from('perfiles').select('perfil').eq('id', userId).single();
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
