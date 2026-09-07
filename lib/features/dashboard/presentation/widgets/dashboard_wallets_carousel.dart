import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:cakeu/features/wallets/presentation/widgets/adjust_balance_sheet.dart';
import 'package:cakeu/features/wallets/presentation/widgets/wallet_transfer_sheet.dart';
import 'package:cakeu/features/wallets/presentation/pages/manage_wallets_page.dart';

class DashboardWalletsCarousel extends StatelessWidget {
  const DashboardWalletsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Dompet & Rekening',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => WalletTransferSheet.show(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Pindah Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton(
                  onPressed: () => ManageWalletsPage.open(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Kelola', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal List of Wallets
        if (wallets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Memuat dompet & rekening...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: wallets.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == wallets.length) {
                  // Tombol Tambah Dompet Baru
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ManageWalletsPage.open(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                            SizedBox(height: 6),
                            Text(
                              'Tambah',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final wallet = wallets[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => AdjustBalanceSheet.show(context, wallet),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 155,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: wallet.colorValue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(wallet.iconData, color: wallet.colorValue, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saldo',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatRupiah(wallet.currentBalance),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: wallet.currentBalance >= 0 ? AppColors.textPrimary : AppColors.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
