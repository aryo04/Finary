import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/features/auth/presentation/providers/auth_provider.dart';
import 'package:cakeu/features/security/presentation/widgets/security_keypad.dart';

/// Modal bottom sheet for setting up a 6-digit security PIN.
class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PinSetupSheet(),
    );
  }

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  String _pin = '';
  String _confirmedPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isLoading = false;

  void _onKeyPressed(String key) {
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmedPin.length < 6) {
          _confirmedPin += key;
          if (_confirmedPin.length == 6) {
            _handlePinComplete();
          }
        }
      } else {
        if (_pin.length < 6) {
          _pin += key;
          if (_pin.length == 6) {
            _isConfirming = true;
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmedPin.isNotEmpty) {
          _confirmedPin = _confirmedPin.substring(0, _confirmedPin.length - 1);
        } else {
          _isConfirming = false;
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _handlePinComplete() async {
    if (_pin != _confirmedPin) {
      setState(() {
        _errorMessage = 'PIN konfirmasi tidak cocok. Silakan ulangi.';
        _confirmedPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'Gagal memuat sesi akun.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await VaultSecurityService().setupPinAndVault(
      pin: _pin,
      userId: userId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Brankas Privasi & PIN berhasil diaktifkan!'),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      setState(() => _errorMessage = 'Gagal menyimpan PIN.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _isConfirming ? _confirmedPin : _pin;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            _isConfirming ? 'Konfirmasi PIN 6-Digit' : 'Buat PIN Brankas Privasi',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _isConfirming
                ? 'Masukkan kembali PIN 6-digit untuk memastikan'
                : 'PIN ini digunakan untuk mengenkripsi catatan keuangan Anda',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // PIN Indicator Dots
          PinIndicatorDots(
            filledDots: currentInput.length,
            dotSize: 14,
            spacing: 8,
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )
          else ...[
            const SizedBox(height: 10),
            SecurityKeypad(
              onKeyPressed: _onKeyPressed,
              onBackspace: _onBackspace,
              buttonWidth: 72,
              buttonHeight: 60,
              fontSize: 22,
              verticalPadding: 6,
            ),
          ],
        ],
      ),
    );
  }
}
