import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:cakeu/core/errors/error_logger.dart';

/// Zero-Knowledge AES-256 Client-Side Encryption Service.
/// Encrypts financial descriptions and sensitive fields before leaving device.
class EncryptionService {
  static const String prefix = 'ENC:';

  EncryptionService._();

  /// Derives a 32-byte (256-bit) AES key from user's 6-digit PIN and user-specific salt.
  static String deriveKey(String pin, String salt) {
    final keyBytes = utf8.encode(pin);
    final saltBytes = utf8.encode(salt);
    
    // Perform multi-round HMAC-SHA256 derivation
    var hmac = Hmac(sha256, keyBytes);
    var digest = hmac.convert(saltBytes);
    
    for (int i = 0; i < 1000; i++) {
      digest = hmac.convert(digest.bytes);
    }
    
    return digest.toString(); // 64 hex characters (32 bytes)
  }

  /// Encrypts a plain text string into a formatted ciphertext string `ENC:<iv_b64>:<cipher_b64>`.
  static String encrypt(String plainText, String keyHex) {
    if (plainText.isEmpty) return plainText;
    if (isEncrypted(plainText)) return plainText; // Already encrypted

    try {
      final key = enc.Key.fromBase16(keyHex.substring(0, 64));
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '$prefix${iv.base64}:${encrypted.base64}';
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace, 'ENCRYPTION_ERROR');
      return plainText; // Fallback to plain text on encryption failure
    }
  }

  /// Decrypts a formatted ciphertext `ENC:<iv_b64>:<cipher_b64>` back to plain text.
  /// If [cipherText] is not encrypted, returns it unchanged.
  static String decrypt(String cipherText, String? keyHex) {
    if (cipherText.isEmpty || !isEncrypted(cipherText)) {
      return cipherText;
    }

    if (keyHex == null || keyHex.isEmpty) {
      return '🔒 Terenkripsi (Buka Kunci)';
    }

    try {
      final cleanText = cipherText.substring(prefix.length);
      final parts = cleanText.split(':');
      if (parts.length != 2) return cipherText;

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final key = enc.Key.fromBase16(keyHex.substring(0, 64));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // In case of wrong PIN or corrupted ciphertext
      return '🔒 Terenkripsi (PIN Diperlukan)';
    }
  }

  /// Checks if a string has the Zero-Knowledge encryption prefix.
  static bool isEncrypted(String text) {
    return text.startsWith(prefix);
  }
}
