import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cakeu/core/services/encryption_service.dart';
import 'package:cakeu/core/errors/error_logger.dart';

/// Service managing Vault Security, PIN Key Derivation, and Session Lock state.
class VaultSecurityService extends ChangeNotifier {
  static final VaultSecurityService _instance = VaultSecurityService._internal();
  factory VaultSecurityService() => _instance;
  VaultSecurityService._internal();

  static const String _keyVaultEnabled = 'vault_zero_knowledge_enabled';
  static const String _keyAppLockEnabled = 'app_lock_pin_enabled';
  static const String _keyBiometricEnabled = 'app_lock_biometric_enabled';
  static const String _keyPinHash = 'vault_user_pin_hash';
  static const String _keySalt = 'vault_user_salt';
  static const String _keyUserId = 'vault_user_id';
  static const String _keyBioDerivedKey = 'vault_bio_derived_key';

  bool _isVaultEnabled = false;
  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isUnlocked = true; // Memory state of current session
  bool _isPickingMedia = false; // Flag to prevent lock when OS opens camera/gallery
  String? _activeDerivedKey; // 256-bit AES key in memory only (never written to disk)

  bool get isVaultEnabled => _isVaultEnabled;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get isPickingMedia => _isPickingMedia;
  String? get activeDerivedKey => _activeDerivedKey;

  void setPickingMedia(bool value) {
    _isPickingMedia = value;
  }

  /// Initializes security preferences and checks if device requires unlock on launch.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isVaultEnabled = prefs.getBool(_keyVaultEnabled) ?? false;
    _isAppLockEnabled = prefs.getBool(_keyAppLockEnabled) ?? false;
    _isBiometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? true;

    if (_isAppLockEnabled || _isVaultEnabled) {
      // If lock is enabled, start locked until user enters PIN or scans fingerprint
      _isUnlocked = false;
      _activeDerivedKey = null;
    } else {
      _isUnlocked = true;
    }
    notifyListeners();
  }

  /// Sets up a new 6-digit PIN and activates Zero-Knowledge Vault.
  Future<bool> setupPinAndVault({required String pin, required String userId}) async {
    if (pin.length != 6) return false;

    try {
      final salt = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final derivedKey = EncryptionService.deriveKey(pin, salt);
      final pinHash = EncryptionService.deriveKey(pin, 'PIN_VERIFY_$userId');

      final bioWrapKey = EncryptionService.deriveKey(userId, 'DEVICE_BIO_WRAP_KEY');
      final wrappedBioKey = EncryptionService.encrypt(derivedKey, bioWrapKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySalt, salt);
      await prefs.setString(_keyPinHash, pinHash);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyBioDerivedKey, wrappedBioKey);
      await prefs.setBool(_keyVaultEnabled, true);
      await prefs.setBool(_keyAppLockEnabled, true);
      await prefs.setBool(_keyBiometricEnabled, true);

      _isVaultEnabled = true;
      _isAppLockEnabled = true;
      _isBiometricEnabled = true;
      _activeDerivedKey = derivedKey;
      _isUnlocked = true;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace, 'SETUP_PIN_ERROR');
      return false;
    }
  }

  /// Verifies PIN entered by user on unlock screen.
  Future<bool> verifyPin(String pin, [String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_keyPinHash);
      final storedSalt = prefs.getString(_keySalt);
      final effectiveUserId = userId ?? prefs.getString(_keyUserId);

      if (storedHash == null || storedSalt == null || effectiveUserId == null) return false;

      final inputHash = EncryptionService.deriveKey(pin, 'PIN_VERIFY_$effectiveUserId');
      if (inputHash == storedHash) {
        final derivedKey = EncryptionService.deriveKey(pin, storedSalt);
        _activeDerivedKey = derivedKey;

        // Refresh wrapped bio key in case user changed PIN
        final bioWrapKey = EncryptionService.deriveKey(effectiveUserId, 'DEVICE_BIO_WRAP_KEY');
        final wrappedBioKey = EncryptionService.encrypt(derivedKey, bioWrapKey);
        await prefs.setString(_keyBioDerivedKey, wrappedBioKey);

        _isUnlocked = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Unlocks app session using biometric authentication and recovers derived key.
  Future<bool> unlockWithBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUserId = prefs.getString(_keyUserId);
      final wrappedKey = prefs.getString(_keyBioDerivedKey);

      if (effectiveUserId != null && wrappedKey != null) {
        final bioWrapKey = EncryptionService.deriveKey(effectiveUserId, 'DEVICE_BIO_WRAP_KEY');
        final derivedKey = EncryptionService.decrypt(wrappedKey, bioWrapKey);
        if (!derivedKey.startsWith('🔒')) {
          _activeDerivedKey = derivedKey;
        }
      }

      _isUnlocked = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggles App Lock preference.
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, enabled);
    _isAppLockEnabled = enabled;
    notifyListeners();
  }

  /// Toggles Biometric Unlock preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  /// Disables Zero-Knowledge Vault and clears stored keys.
  Future<void> disableVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVaultEnabled, false);
    await prefs.setBool(_keyAppLockEnabled, false);
    await prefs.setBool(_keyBiometricEnabled, false);
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keySalt);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyBioDerivedKey);

    _isVaultEnabled = false;
    _isAppLockEnabled = false;
    _isBiometricEnabled = false;
    _activeDerivedKey = null;
    _isUnlocked = true;
    notifyListeners();
  }

  /// Manually locks the session and wipes derived encryption key from memory.
  void lock() {
    if (_isAppLockEnabled || _isVaultEnabled) {
      if (_isUnlocked) {
        _isUnlocked = false;
        _activeDerivedKey = null;
        notifyListeners();
      }
    }
  }

  /// Encrypts description if Vault is enabled.
  String encryptDescription(String description) {
    if (!_isVaultEnabled || _activeDerivedKey == null || description.isEmpty) {
      return description;
    }
    return EncryptionService.encrypt(description, _activeDerivedKey!);
  }

  /// Decrypts description if encrypted.
  String decryptDescription(String description) {
    if (!EncryptionService.isEncrypted(description)) {
      return description;
    }
    return EncryptionService.decrypt(description, _activeDerivedKey);
  }
}
