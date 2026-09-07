import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/core/services/biometric_service.dart';
import 'package:cakeu/features/security/presentation/widgets/pin_setup_sheet.dart';

/// Privacy & Security Center Page.
class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final VaultSecurityService _vault = VaultSecurityService();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vault,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Privasi & Keamanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Zero-Knowledge Encryption Status Card
              _buildTrustStatusCard(),
              const SizedBox(height: 24),

              // 2. Section Title
              const Text(
                'KONTROL KEAMANAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // App Lock / Biometrics Toggle Card
              _buildSecurityToggleTile(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Kunci Aplikasi (Auto-Lock PIN)',
                subtitle: 'Minta PIN saat aplikasi dibuka atau kembali dari latar belakang',
                value: _vault.isAppLockEnabled,
                onChanged: (val) async {
                  if (val && !_vault.isVaultEnabled) {
                    final success = await PinSetupSheet.show(context);
                    if (success != true) return;
                  } else {
                    await _vault.setAppLockEnabled(val);
                  }
                },
              ),
              if (_canUseBiometrics && (_vault.isAppLockEnabled || _vault.isVaultEnabled)) ...[
                const SizedBox(height: 10),
                _buildSecurityToggleTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Buka dengan Sidik Jari',
                  subtitle: 'Pindai sidik jari langsung tanpa mengetik 6-digit PIN',
                  value: _vault.isBiometricEnabled,
                  onChanged: (val) async {
                    await _vault.setBiometricEnabled(val);
                  },
                ),
              ],
              const SizedBox(height: 10),

              // Zero-Knowledge Vault Encryption Toggle Card
              _buildSecurityToggleTile(
                icon: Icons.enhanced_encryption_rounded,
                iconColor: AppColors.primary,
                title: 'Brankas Privasi (Zero-Knowledge)',
                subtitle: 'Enkripsi teks catatan di HP agar tidak bisa dibaca oleh siapapun di server',
                value: _vault.isVaultEnabled,
                onChanged: (val) async {
                  if (val) {
                    await PinSetupSheet.show(context);
                  } else {
                    _showDisableVaultConfirmation();
                  }
                },
              ),

              if (_vault.isVaultEnabled) ...[
                const SizedBox(height: 10),
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Ubah PIN Brankas 6-Digit',
                  onTap: () => PinSetupSheet.show(context),
                ),
              ],

              const SizedBox(height: 28),

              // 3. Privacy Guarantees Section
              const Text(
                'JAMINAN PRIVASI FINARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuaranteeCard(),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustStatusCard() {
    final isEncrypted = _vault.isVaultEnabled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEncrypted
              ? [const Color(0xFF0F766E), const Color(0xFF0D9488)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isEncrypted ? AppColors.primary : Colors.black).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEncrypted ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEncrypted ? 'Brankas Terenkripsi Aktif' : 'Perlindungan Standar',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEncrypted ? 'Enkripsi Klien AES-256' : 'Row Level Security Aktif',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEncrypted
                ? 'Catatan keuangan Anda diacak di HP menggunakan PIN Anda. Developer dan pihak lain di database hanya melihat kode acak.'
                : 'Data Anda diisolasi per akun di Supabase. Aktifkan Brankas Privasi untuk mengacak tulisan secara matematis di HP.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildGuaranteeItem(
            icon: Icons.money_off_csred_rounded,
            title: 'Bukan Akses Rekening Bank',
            desc: 'Finary murni buku catatan pintar. Kami tidak pernah meminta nomor rekening, password m-banking, maupun OTP.',
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildGuaranteeItem(
            icon: Icons.no_accounts_rounded,
            title: 'Zero Data Selling',
            desc: 'Data finansial Anda tidak akan pernah dijual ke pihak ketiga, pinjol, agensi iklan, atau entitas manapun.',
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildGuaranteeItem(
            icon: Icons.psychology_outlined,
            title: 'AI Tanpa Pelatihan Publik',
            desc: 'Data percakapan finansial Anda diproses langsung melalui koneksi aman dan tidak digunakan untuk melatih AI publik.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDisableVaultConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Brankas?'),
        content: const Text(
          'Menonaktifkan brankas akan menghentikan enkripsi otomatis untuk catatan baru. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _vault.disableVault();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }
}
