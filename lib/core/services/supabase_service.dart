import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/constants/app_constants.dart';

/// Centralized Supabase service providing access to the Supabase client.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Initializes the Supabase client safely.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }
  }

  /// Returns whether Supabase has been initialized.
  static bool get isInitialized => _initialized;

  /// Returns the Supabase client instance safely.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the Supabase auth instance.
  static GoTrueClient get auth => client.auth;

  /// Returns the currently authenticated user, or null.
  static User? get currentUser {
    try {
      if (!_initialized) return null;
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently signed in.
  static bool get isAuthenticated => currentUser != null;
}
