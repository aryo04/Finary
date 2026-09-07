import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/core/services/biometric_service.dart';
import 'package:cakeu/features/auth/presentation/providers/auth_provider.dart';
import 'package:cakeu/features/security/presentation/widgets/security_keypad.dart';

/// Full-screen lock overlay for PIN unlock.
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    if (mounted) {
      setState(() => _canUseBiometrics = available);
      if (available && VaultSecurityService().isBiometricEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticateWithBiometric();
        });
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final authenticated = await BiometricService.authenticate(
      reason: 'Sentuh sensor sidik jari untuk membuka Finary',
    );

    if (authenticated && mounted) {
      final success = await VaultSecurityService().unlockWithBiometric();
      if (success) {
        widget.onUnlocked();
      }
    }
  }

  void _onKeyPressed(String key) {
    if (_pin.length < 6) {
      setState(() {
        _errorMessage = null;
        _pin += key;
        if (_pin.length == 6) {
          _verifyPin();
        }
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? SupabaseService.currentUser?.id;

    setState(() => _isLoading = true);

    final isValid = await VaultSecurityService().verifyPin(_pin, userId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'PIN salah. Silakan coba lagi.';
        _pin = '';
      });
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa PIN 6-Digit?'),
        content: const Text(
          'Untuk alasan keamanan privasi, Anda dapat keluar (logout) dari akun ini dan masuk kembali dengan email & password Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await VaultSecurityService().disableVault();
              if (mounted) {
                await context.read<AuthProvider>().signOut();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Keluar Akun'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // App Icon / Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Finary Terkunci',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan PIN 6-digit untuk membuka brankas Anda',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            PinIndicatorDots(
              filledDots: _pin.length,
              dotSize: 16,
              spacing: 10,
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 13),
              ),

            const Spacer(),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              )
            else ...[
              SecurityKeypad(
                onKeyPressed: _onKeyPressed,
                onBackspace: _onBackspace,
                onBiometricPressed: _authenticateWithBiometric,
                showBiometric: _canUseBiometrics,
                fontSize: 26,
                verticalPadding: 8,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _showForgotPinDialog,
                child: const Text(
                  'Lupa PIN? Keluar Akun',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
