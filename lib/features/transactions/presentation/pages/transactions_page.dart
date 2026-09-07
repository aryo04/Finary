import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transaction_item_tile.dart';
import 'package:cakeu/shared/widgets/date_navigator_bar.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transactions_segmented_filter.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transactions_summary_strip.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transactions_pagination_bar.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all'; // 'all', 'expense', 'income'
  DateTime _selectedDate = DateTime.now();
  bool _filterByDate = true;
  int _pageSize = 5;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
      context.read<WalletProvider>().fetchWallets();
    });
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _currentPage = 0;
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _currentPage = 0;
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterByDate = true;
        _currentPage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final allTransactions = txProvider.transactions;

    // Filter berdasarkan Tanggal, Dompet & Tipe Transaksi
    final filteredTransactions = allTransactions.where((t) {
      if (_filterByDate && !AppDateFormatter.isSameDay(t.transactionDate, _selectedDate)) {
        return false;
      }
      if (txProvider.filterWalletId != null && t.walletId != txProvider.filterWalletId) {
        return false;
      }
      if (_selectedFilter == 'expense') return t.isExpense;
      if (_selectedFilter == 'income') return t.isIncome;
      if (_selectedFilter == 'transfer') return t.isTransfer;
      return true;
    }).toList();

    final totalItems = filteredTransactions.length;
    final totalPages = (totalItems / _pageSize).ceil();

    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final startIndex = _currentPage * _pageSize;
    final endIndex = math.min(startIndex + _pageSize, totalItems);
    final pagedTransactions = totalItems > 0
        ? filteredTransactions.sublist(startIndex, endIndex)
        : <TransactionModel>[];

    final dayExpense = filteredTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayIncome = filteredTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/transactions/add'),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Catat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () => txProvider.fetchTransactions(forceRefresh: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Date Navigator Bar
          DateNavigatorBar(
            selectedDate: _selectedDate,
            onPrevious: _filterByDate ? _previousDay : null,
            onNext: _filterByDate ? _nextDay : null,
            onPickDate: _pickCustomDate,
            customTitle: _filterByDate ? null : 'Semua Tanggal',
            badgeText: _filterByDate ? 'Semua' : 'Hari Ini',
            isBadgeHighlighted: !_filterByDate,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            onTapBadge: () {
              setState(() {
                _filterByDate = !_filterByDate;
                _currentPage = 0;
              });
            },
          ),

          // 2. Sleek Segmented Type Filter
          TransactionsSegmentedFilter(
            selectedFilter: _selectedFilter,
            allList: allTransactions,
            filterByDate: _filterByDate,
            selectedDate: _selectedDate,
            onFilterChanged: (val) {
              setState(() {
                _selectedFilter = val;
                _currentPage = 0;
              });
            },
          ),

          // 2.5 Wallet Filter Chips Bar
          Consumer<WalletProvider>(
            builder: (context, walletProv, _) {
              final wallets = walletProv.wallets;
              if (wallets.isEmpty) return const SizedBox.shrink();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      selected: txProvider.filterWalletId == null,
                      label: const Text('Semua Dompet'),
                      avatar: const Icon(Icons.apps_rounded, size: 16),
                      onSelected: (_) => txProvider.setFilterWallet(null),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: txProvider.filterWalletId == null ? FontWeight.bold : FontWeight.normal,
                        color: txProvider.filterWalletId == null ? AppColors.primary : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 8),
                    ...wallets.map((w) {
                      final isSelected = txProvider.filterWalletId == w.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(w.name),
                          avatar: Icon(w.iconData, size: 16, color: isSelected ? w.colorValue : AppColors.textSecondary),
                          onSelected: (_) => txProvider.setFilterWallet(w.id),
                          selectedColor: w.colorValue.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? w.colorValue : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? w.colorValue : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // 3. Mini Total Summary Bar
          if (filteredTransactions.isNotEmpty)
            TransactionsSummaryStrip(
              income: dayIncome,
              expense: dayExpense,
            ),

          // 4. Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => txProvider.fetchTransactions(forceRefresh: true),
              child: txProvider.isLoading && allTransactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: pagedTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = pagedTransactions[index];
                            return TransactionItemTile(
                              tx: tx,
                              provider: txProvider,
                            );
                          },
                        ),
            ),
          ),

          // 5. Bottom Pagination Bar
          if (totalItems > 0)
            TransactionsPaginationBar(
              totalItems: totalItems,
              totalPages: totalPages,
              currentPage: _currentPage,
              pageSize: _pageSize,
              startIndex: startIndex,
              endIndex: endIndex,
              onPreviousPage: () => setState(() => _currentPage--),
              onNextPage: () => setState(() => _currentPage++),
              onPageSizeChanged: (val) {
                setState(() {
                  _pageSize = val;
                  _currentPage = 0;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filterByDate
                  ? 'Belum ada transaksi pada ${AppDateFormatter.formatDayTitle(_selectedDate)}'
                  : 'Belum ada data transaksi yang tersimpan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/transactions/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Catat Transaksi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
