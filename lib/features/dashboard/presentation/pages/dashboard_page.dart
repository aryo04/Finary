import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/auth/presentation/providers/auth_provider.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:cakeu/features/dashboard/presentation/widgets/dashboard_balance_card.dart';
import 'package:cakeu/features/dashboard/presentation/widgets/dashboard_income_expense_row.dart';
import 'package:cakeu/features/dashboard/presentation/widgets/dashboard_wallets_carousel.dart';
import 'package:cakeu/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:cakeu/features/dashboard/presentation/widgets/dashboard_recent_transactions.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
      context.read<WalletProvider>().fetchWallets();
    });
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      context.read<TransactionProvider>().fetchTransactions(forceRefresh: true),
      context.read<WalletProvider>().fetchWallets(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final txProvider = context.watch<TransactionProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final userName =
        user?.userMetadata?['full_name'] as String? ?? user?.email?.split('@').first ?? 'Teman';
    final recentTransactions = txProvider.transactions.take(5).toList();

    // Total kekayaan bersih dari semua dompet (jika ada dompet dengan saldo awal)
    final totalBalance = walletProvider.wallets.isNotEmpty
        ? walletProvider.totalWealth
        : txProvider.balance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/finary_logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Halo, $userName 👋',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: _refreshAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Luxury Gradient Balance Card (Total Saldo Semua Dompet)
            DashboardBalanceCard(
              balance: totalBalance,
              isBalanceVisible: _isBalanceVisible,
              onToggleVisibility: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
            ),
            const SizedBox(height: 16),

            // 2. Income & Expense Metric Cards
            DashboardIncomeExpenseRow(
              totalIncome: txProvider.totalIncome,
              totalExpense: txProvider.totalExpense,
              isBalanceVisible: _isBalanceVisible,
            ),
            const SizedBox(height: 20),

            // 3. Multi-Wallets & Accounts Carousel
            const DashboardWalletsCarousel(),
            const SizedBox(height: 22),

            // 4. Quick Action Buttons
            const DashboardQuickActions(),
            const SizedBox(height: 24),

            // 5. Recent Transactions List
            DashboardRecentTransactions(
              transactions: recentTransactions,
              isLoading: txProvider.isLoading,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
