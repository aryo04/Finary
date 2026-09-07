/// Base exception class for all application exceptions.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Exception thrown when a server or Supabase operation fails.
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    super.code,
    super.details,
    this.statusCode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔐 AUTHENTICATION EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Generic Authentication Exception.
class AppAuthException extends AppException {
  const AppAuthException(super.message, {super.code, super.details});
}

/// Thrown when email or password is wrong.
class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException([
    super.message = 'Email atau kata sandi yang Anda masukkan salah.',
    String? code,
  ]) : super(code: code ?? 'INVALID_CREDENTIALS');
}

/// Thrown when an email is not found in database during login.
class UserNotFoundException extends AppAuthException {
  const UserNotFoundException([
    super.message = 'Akun dengan email ini belum terdaftar.',
    String? code,
  ]) : super(code: code ?? 'USER_NOT_FOUND');
}

/// Thrown when trying to register with an email already taken.
class EmailAlreadyInUseException extends AppAuthException {
  const EmailAlreadyInUseException([
    super.message = 'Email ini sudah terdaftar.',
    String? code,
  ]) : super(code: code ?? 'EMAIL_ALREADY_IN_USE');
}

/// Thrown when password is too weak.
class WeakPasswordException extends AppAuthException {
  const WeakPasswordException([
    super.message = 'Kata sandi terlalu lemah.',
    String? code,
  ]) : super(code: code ?? 'WEAK_PASSWORD');
}

/// Thrown when email confirmation is pending.
class EmailNotConfirmedException extends AppAuthException {
  const EmailNotConfirmedException([
    super.message = 'Email belum dikonfirmasi.',
    String? code,
  ]) : super(code: code ?? 'EMAIL_NOT_CONFIRMED');
}

/// Thrown when token or session is expired.
class SessionExpiredException extends AppAuthException {
  const SessionExpiredException([
    super.message = 'Sesi login telah berakhir.',
    String? code,
  ]) : super(code: code ?? 'SESSION_EXPIRED');
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌐 SYSTEM & IO EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Exception thrown when there is no network connection or timeout.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Koneksi internet tidak stabil atau terputus.',
    String? code,
  ]) : super(code: code ?? 'NETWORK_ERROR');
}

/// Exception thrown when local cache or database read/write fails.
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}

/// Exception thrown when user input validation fails.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Exception thrown when a requested resource is not found.
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Data yang dicari tidak ditemukan.',
    String? code,
  ]) : super(code: code ?? 'NOT_FOUND');
}
