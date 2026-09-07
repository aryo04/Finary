import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:cakeu/core/errors/exceptions.dart';
import 'package:cakeu/core/errors/failures.dart';
import 'package:cakeu/core/errors/error_logger.dart';

/// Centralized Error Handler to convert dynamic exceptions into user-friendly Failures.
class ErrorHandler {
  ErrorHandler._();

  /// Converts any thrown error or exception into a user-friendly [Failure].
  static Failure handle(dynamic error, [StackTrace? stackTrace]) {
    // Log error for debugging
    ErrorLogger.log(error, stackTrace);

    if (error is Failure) {
      return error;
    }

    if (error is SocketException) {
      return const NetworkFailure('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
    }

    if (error is supabase.FunctionException) {
      final details = error.details;
      final msg = details is Map
          ? (details['message'] as String? ?? details.toString())
          : (error.reasonPhrase ?? 'Gagal memproses permintaan ke server AI.');
      return ServerFailure(msg, error.status.toString());
    }

    if (error is supabase.PostgrestException) {
      return _handlePostgrestException(error);
    }

    if (error is supabase.AuthException) {
      return _handleSupabaseAuthException(error);
    }

    if (error is AppAuthException) {
      return _handleAppAuthException(error);
    }

    if (error is AppException) {
      return ServerFailure(error.message, error.code);
    }

    return ServerFailure(
      error is String
          ? error
          : 'Terjadi kendala yang tidak terduga. Silakan coba beberapa saat lagi.',
    );
  }

  /// Translates Supabase Postgrest database errors to Indonesian Failures.
  static Failure _handlePostgrestException(supabase.PostgrestException error) {
    final code = error.code;
    final msg = error.message.toLowerCase();

    if (code == '23505' || msg.contains('duplicate key')) {
      return const ValidationFailure('Data dengan nama atau identitas ini sudah ada.');
    }

    if (code == '23503' || msg.contains('foreign key')) {
      return const ValidationFailure('Data tidak dapat dihapus karena masih digunakan di riwayat transaksi.');
    }

    if (code == 'PGRST116' || msg.contains('0 rows')) {
      return const NotFoundFailure('Data tidak ditemukan.');
    }

    if (msg.contains('jwt') || msg.contains('token') || msg.contains('unauthorized')) {
      return const SessionExpiredFailure('Sesi Anda telah berakhir. Silakan masuk kembali.');
    }

    return ServerFailure('Terjadi kesalahan database: ${error.message}', code);
  }

  /// Translates Supabase Auth errors to specific Auth Failures.
  static Failure _handleSupabaseAuthException(supabase.AuthException error) {
    final msg = error.message.toLowerCase();
    final code = error.statusCode;

    // 1. Email Belum Dikonfirmasi / Diverifikasi (Prioritas Utama)
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed') ||
        msg.contains('not confirmed') ||
        msg.contains('not verified') ||
        msg.contains('unconfirmed') ||
        msg.contains('confirm your email') ||
        msg.contains('verify your email')) {
      return const EmailNotConfirmedFailure();
    }

    // 2. Salah Email / Password
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid grant') ||
        msg.contains('invalid password') ||
        msg.contains('wrong password')) {
      return const InvalidCredentialsFailure();
    }

    // 3. Akun / Email Belum Terdaftar
    if (msg.contains('user not found') ||
        msg.contains('user does not exist') ||
        msg.contains('no user found')) {
      return const UserNotFoundFailure();
    }

    // 4. Email Sudah Terdaftar (Saat Register)
    if (msg.contains('user already registered') ||
        msg.contains('email already in use') ||
        msg.contains('already exists') ||
        msg.contains('duplicate') ||
        msg.contains('user_already_exists')) {
      return const EmailAlreadyInUseFailure();
    }

    // 5. Password Lemah
    if (msg.contains('password') && (msg.contains('short') || msg.contains('weak') || msg.contains('least'))) {
      return const WeakPasswordFailure();
    }

    // 6. Sesi / Token Kedaluwarsa
    if (msg.contains('jwt') || msg.contains('expired') || msg.contains('session')) {
      return const SessionExpiredFailure();
    }

    return AuthFailure(error.message, code: code);
  }

  /// Translates internal AppAuthException to specific Auth Failures.
  static Failure _handleAppAuthException(AppAuthException error) {
    if (error is InvalidCredentialsException) return const InvalidCredentialsFailure();
    if (error is UserNotFoundException) return const UserNotFoundFailure();
    if (error is EmailAlreadyInUseException) return const EmailAlreadyInUseFailure();
    if (error is WeakPasswordException) return const WeakPasswordFailure();
    if (error is EmailNotConfirmedException) return const EmailNotConfirmedFailure();
    if (error is SessionExpiredException) return const SessionExpiredFailure();
    return AuthFailure(error.message, code: error.code);
  }
}
