/// Base failure class representing a user-facing error state in presentation layer.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Failure representing server or database errors.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.',
    String? code,
  ]) : super(code: code);
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔐 AUTHENTICATION FAILURES (Autentikasi & Akun Pengguna)
// ─────────────────────────────────────────────────────────────────────────────

/// Generic Authentication Failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Failure when email or password is wrong during login.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Email atau kata sandi yang Anda masukkan salah. Silakan periksa kembali.',
    String? code,
  ]) : super(code: code ?? 'INVALID_CREDENTIALS');
}

/// Failure when attempting to login with an unregistered email/account.
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'Akun dengan email ini belum terdaftar. Silakan daftar akun baru terlebih dahulu.',
    String? code,
  ]) : super(code: code ?? 'USER_NOT_FOUND');
}

/// Failure when registering with an email that is already registered.
class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'Email ini sudah terdaftar. Silakan langsung masuk dengan akun Anda.',
    String? code,
  ]) : super(code: code ?? 'EMAIL_ALREADY_IN_USE');
}

/// Failure when password does not meet security requirements.
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'Kata sandi terlalu pendek atau lemah. Gunakan minimal 6 karakter.',
    String? code,
  ]) : super(code: code ?? 'WEAK_PASSWORD');
}

/// Failure when user email has not been verified/confirmed yet.
class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure([
    super.message = 'Email Anda belum diverifikasi. Silakan periksa tautan konfirmasi di kotak masuk email Anda.',
    String? code,
  ]) : super(code: code ?? 'EMAIL_NOT_CONFIRMED');
}

/// Failure when the login session / JWT token has expired.
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure([
    super.message = 'Sesi Anda telah berakhir demi keamanan. Silakan masuk kembali.',
    String? code,
  ]) : super(code: code ?? 'SESSION_EXPIRED');
}

/// Failure when password confirmation does not match.
class PasswordMismatchFailure extends AuthFailure {
  const PasswordMismatchFailure([
    super.message = 'Konfirmasi kata sandi tidak cocok. Silakan pastikan kedua kata sandi sama.',
    String? code,
  ]) : super(code: code ?? 'PASSWORD_MISMATCH');
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌐 OTHER SYSTEM FAILURES
// ─────────────────────────────────────────────────────────────────────────────

/// Failure representing network disconnection or timeout.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak dapat terhubung ke internet. Periksa koneksi data atau Wi-Fi Anda.',
    String? code,
  ]) : super(code: code ?? 'NETWORK_UNAVAILABLE');
}

/// Failure representing validation issues in forms or user inputs.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Failure representing empty or not found entities.
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'Data yang Anda cari tidak ditemukan.',
    String? code,
  ]) : super(code: code ?? 'NOT_FOUND');
}

/// Failure representing AI processing issues.
class AiFailure extends Failure {
  const AiFailure(super.message, {super.code});
}
