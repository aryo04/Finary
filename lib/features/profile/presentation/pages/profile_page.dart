import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/auth/presentation/providers/auth_provider.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/chatbot/presentation/providers/chatbot_provider.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:cakeu/core/services/vault_security_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final fullName =
        user?.userMetadata?['full_name'] as String? ?? user?.email?.split('@').first ?? 'Pengguna Finary';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Luxury Avatar & User Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.incomeLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: AppColors.income),
                      SizedBox(width: 4),
                      Text(
                        'Akun Aktif • Terhubung Supabase',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Settings Menu Card
          const Text(
            'Pengaturan & Preferensi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.category_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryContainer,
                  label: 'Kategori Keuangan',
                  subtitle: 'Kelola kategori pemasukan & pengeluaran',
                  onTap: () => context.push('/categories'),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: Color(0xFFF1F5F9),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.warning,
                  iconBg: AppColors.warningLight,
                  label: 'Notifikasi',
                  subtitle: 'Pengingat pencatatan keuangan',
                  onTap: () {},
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: Color(0xFFF1F5F9),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryContainer,
                  label: 'Privasi & Keamanan',
                  subtitle: 'Brankas enkripsi & kunci biometrik',
                  onTap: () => context.push('/privacy-security'),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 16,
                  color: Color(0xFFF1F5F9),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  iconBg: AppColors.surfaceVariant,
                  label: 'Bantuan & FAQ',
                  subtitle: 'Panduan penggunaan aplikasi Finary',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Keluar Akun'),
                    content: const Text('Apakah Anda yakin ingin keluar dari akun Finary?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  // Bersihkan cache in-memory data akun sebelumnya
                  context.read<TransactionProvider>().clearData();
                  context.read<CategoryProvider>().clearData();
                  context.read<ChatbotProvider>().clearData();
                  context.read<WalletProvider>().clearData();
                  VaultSecurityService().lock();

                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.expense, size: 18),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expenseLight, width: 1.5),
                backgroundColor: AppColors.expenseLight.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
    );
  }
}
