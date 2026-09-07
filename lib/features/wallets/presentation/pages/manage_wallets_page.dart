import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:cakeu/features/wallets/presentation/widgets/adjust_balance_sheet.dart';
import 'package:cakeu/features/wallets/presentation/widgets/transfer_history_sheet.dart';
import 'package:cakeu/features/wallets/presentation/widgets/wallet_transfer_sheet.dart';

class ManageWalletsPage extends StatelessWidget {
  const ManageWalletsPage({super.key});

  static Future<void> open(BuildContext context) {
    return context.push('/wallets');
  }

  void _showAddEditWalletDialog(BuildContext context, {WalletModel? wallet}) {
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController = TextEditingController(
      text: wallet != null
          ? (wallet.currentBalance < 0
              ? '0'
              : wallet.currentBalance.toInt().toString())
          : '0',
    );
    String selectedType = wallet?.type ?? 'cash';
    String selectedColor = wallet?.color ?? '#0D9488';
    String selectedIcon = wallet?.icon ?? 'account_balance_wallet';

    final colorOptions = [
      '#0D9488', // Teal
      '#2563EB', // Blue
      '#10B981', // Green
      '#8B5CF6', // Purple
      '#F59E0B', // Amber
      '#EF4444', // Red
      '#EC4899', // Pink
      '#64748B', // Slate
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            wallet == null ? 'Tambah Dompet / Rekening' : 'Edit Dompet',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Dompet / Rekening:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Misal: BCA, Dompet Tunai, GoPay',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Jenis Dompet:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'cash', label: Text('Tunai'), icon: Icon(Icons.payments_rounded, size: 16)),
                    ButtonSegment(value: 'bank', label: Text('Bank'), icon: Icon(Icons.account_balance_rounded, size: 16)),
                    ButtonSegment(value: 'ewallet', label: Text('E-Wallet'), icon: Icon(Icons.smartphone_rounded, size: 16)),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (set) {
                    setDialogState(() {
                      selectedType = set.first;
                      if (selectedType == 'cash') selectedIcon = 'payments';
                      if (selectedType == 'bank') selectedIcon = 'account_balance';
                      if (selectedType == 'ewallet') selectedIcon = 'smartphone';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  wallet == null ? 'Saldo Awal (Rp):' : 'Saldo Saat Ini (Rp):',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Warna Tema:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((c) {
                    final colorVal = AppColors.fromHex(c);
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final initBal = double.tryParse(balanceController.text.replaceAll('.', '').trim()) ?? 0.0;
                if (name.isEmpty) return;

                final provider = context.read<WalletProvider>();
                if (wallet == null) {
                  await provider.createWallet(
                    name: name,
                    type: selectedType,
                    initialBalance: initBal,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                } else {
                  await provider.updateWallet(
                    id: wallet.id,
                    name: name,
                    type: selectedType,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  if ((initBal - wallet.currentBalance).abs() > 0.01) {
                    await provider.setWalletBalance(
                      walletId: wallet.id,
                      targetBalance: initBal,
                    );
                  }
                }
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Dompet & Rekening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Pindah Saldo',
            onPressed: () => TransferHistorySheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Pindah Saldo',
            onPressed: () => WalletTransferSheet.show(context),
          ),
        ],
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Total Wealth Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Kekayaan Bersih (Semua Dompet)',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.formatRupiah(walletProvider.totalWealth),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Terbagi ke dalam ${wallets.length} dompet & rekening',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Dompet & Rekening', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    FilledButton.tonalIcon(
                      onPressed: () => _showAddEditWalletDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // List of Wallets
                ...wallets.map((wallet) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      onTap: () => AdjustBalanceSheet.show(context, wallet),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: wallet.colorValue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(wallet.iconData, color: wallet.colorValue, size: 24),
                      ),
                      title: Row(
                        children: [
                          Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (wallet.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Utama', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          CurrencyFormatter.formatRupiah(wallet.currentBalance),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: wallet.currentBalance >= 0 ? AppColors.textPrimary : AppColors.error,
                          ),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'adjust') {
                            AdjustBalanceSheet.show(context, wallet);
                          } else if (action == 'edit') {
                            _showAddEditWalletDialog(context, wallet: wallet);
                          } else if (action == 'transfer') {
                            WalletTransferSheet.show(context, initialFromWallet: wallet);
                          } else if (action == 'delete') {
                            walletProvider.deleteWallet(wallet.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'adjust', child: Row(children: [Icon(Icons.tune_rounded, size: 18, color: AppColors.primary), SizedBox(width: 8), Text('Sesuaikan Saldo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))])),
                          const PopupMenuItem(value: 'transfer', child: Row(children: [Icon(Icons.swap_horiz, size: 18), SizedBox(width: 8), Text('Pindah Saldo')])),
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Dompet')])),
                          if (!wallet.isDefault)
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
