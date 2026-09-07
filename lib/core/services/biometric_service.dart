import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cakeu/core/errors/error_logger.dart';

/// Helper service for Biometric (Fingerprint / Face ID) authentication.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._();

  /// Checks whether device hardware supports biometric authentication and has enrolled biometrics.
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace, 'BIOMETRIC_CHECK_ERROR');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts system biometric authentication dialog.
  static Future<bool> authenticate({
    String reason = 'Sentuh sensor sidik jari untuk membuka Finary',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace, 'BIOMETRIC_AUTH_ERROR');
      return false;
    } catch (_) {
      return false;
    }
  }
}
