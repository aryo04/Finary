import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/errors/error_handler.dart';
import 'package:cakeu/features/auth/data/models/user_profile_model.dart';
import 'package:cakeu/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _repository.authStateChanges.listen((data) {
      if (data.session != null) {
        loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  UserProfileModel? get profile => _profile;
  User? get user => _repository.currentUser;
  bool get isAuthenticated => _repository.currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkSession() async {
    if (isAuthenticated) {
      await loadProfile();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signOut();
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace);
    } finally {
      _profile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _repository.getProfile();
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace);
    }
  }
}
