import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/features/auth/data/models/user_profile_model.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserProfileModel?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfileModel.fromJson(data);
  }

  Future<void> updateProfile({required String fullName}) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}
