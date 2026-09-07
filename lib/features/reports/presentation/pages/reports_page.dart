import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/reports/data/models/category_breakdown_data.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_month_navigator.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_split_summary_card.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_donut_chart.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_weekly_bar_chart.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_metrics_grid.dart';
import 'package:cakeu/features/reports/presentation/widgets/reports_category_list.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _selectedTab = 'expense'; // 'expense' or 'income'
  String? _selectedWalletId; // Filter per dompet / rekening

  late AnimationController _animController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
      context.read<CategoryProvider>().fetchCategories();
      context.read<WalletProvider>().fetchWallets();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    _animController.forward(from: 0.0);
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    _animController.forward(from: 0.0);
  }

  Future<void> _pickCustomMonth() async {
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
        _selectedDate = DateTime(picked.year, picked.month);
      });
      _animController.forward(from: 0.0);
    }
  }


  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final allTransactions = txProvider.transactions;
    final wallets = walletProvider.wallets;

    final monthlyTransactions = allTransactions.where((t) {
      final isSameMonth = t.transactionDate.year == _selectedDate.year &&
          t.transactionDate.month == _selectedDate.month;
      if (!isSameMonth) return false;
      if (_selectedWalletId != null && t.walletId != _selectedWalletId) {
        return false;
      }
      return true;
    }).toList();

    final totalIncome = monthlyTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);

    final totalExpense = monthlyTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);

    final netSavings = totalIncome - totalExpense;
    final isExpenseTab = _selectedTab == 'expense';

    // Kelompokkan kategori berdasarkan tab yang dipilih
    final Map<String, CategoryBreakdownData> categoryMap = {};
    final targetTransactions = monthlyTransactions.where(
      (t) => isExpenseTab ? t.isExpense : t.isIncome,
    );

    for (final tx in targetTransactions) {
      String name = tx.category?.name ?? (isExpenseTab ? 'Lainnya' : 'Pemasukan Lain');
      String? colorHex = tx.category?.color;
      String iconName = tx.category?.icon ?? 'category';

      if (name == 'Lainnya' && tx.categoryId != null && catProvider.categories.isNotEmpty) {
        final foundCat = catProvider.categories.where((c) => c.id == tx.categoryId).firstOrNull;
        if (foundCat != null) {
          name = foundCat.name;
          colorHex = foundCat.color;
          iconName = foundCat.icon;
        }
      }

      final catColor = AppColors.fromHex(
        colorHex,
        fallback: isExpenseTab ? AppColors.expense : AppColors.income,
      );

      if (categoryMap.containsKey(name)) {
        categoryMap[name]!.total += tx.amount;
        categoryMap[name]!.count += 1;
      } else {
        categoryMap[name] = CategoryBreakdownData(
          name: name,
          total: tx.amount,
          color: catColor,
          icon: CategoryModel.iconFromName(iconName, isExpense: isExpenseTab),
          count: 1,
        );
      }
    }

    final categoryList = categoryMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final activeTotal = isExpenseTab ? totalExpense : totalIncome;
    final weeklyExpenses = _calculateWeeklyTotals(monthlyTransactions, isExpenseTab);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Finansial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () {
              txProvider.fetchTransactions(forceRefresh: true);
              walletProvider.fetchWallets(forceRefresh: true);
              _animController.forward(from: 0.0);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            txProvider.fetchTransactions(forceRefresh: true),
            walletProvider.fetchWallets(forceRefresh: true),
          ]);
          _animController.forward(from: 0.0);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // 1. Month Navigator
            ReportsMonthNavigator(
              selectedDate: _selectedDate,
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
              onPickCustomMonth: _pickCustomMonth,
            ),
            const SizedBox(height: 10),

            // 1.5 Wallet Filter Chips
            if (wallets.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedWalletId == null,
                      label: const Text('Semua Dompet'),
                      avatar: const Icon(Icons.apps_rounded, size: 16),
                      onSelected: (_) {
                        setState(() => _selectedWalletId = null);
                        _animController.forward(from: 0.0);
                      },
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedWalletId == null ? FontWeight.bold : FontWeight.normal,
                        color: _selectedWalletId == null ? AppColors.primary : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 8),
                    ...wallets.map((w) {
                      final isSelected = _selectedWalletId == w.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(w.name),
                          avatar: Icon(w.iconData, size: 16, color: isSelected ? w.colorValue : AppColors.textSecondary),
                          onSelected: (_) {
                            setState(() {
                              _selectedWalletId = isSelected ? null : w.id;
                            });
                            _animController.forward(from: 0.0);
                          },
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
              ),
              const SizedBox(height: 12),
            ],

            // 2. High Contrast Income vs Expense Split Cards & Net Savings Meter
            ReportsSplitSummaryCard(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              netSavings: netSavings,
            ),
            const SizedBox(height: 20),

            // 3. Modern Segmented Tab: [ Pengeluaran | Pemasukan ]
            _buildSegmentedTab(),
            const SizedBox(height: 16),

            if (activeTotal > 0) ...[
              // 4. Animated Donut Chart Section
              ReportsDonutChart(
                totalAmount: activeTotal,
                categories: categoryList,
                isExpense: isExpenseTab,
                animation: _chartAnimation,
              ),
              const SizedBox(height: 18),

              // 5. Weekly Cashflow Bar Chart
              ReportsWeeklyBarChart(
                weeklyTotals: weeklyExpenses,
                isExpense: isExpenseTab,
                animation: _chartAnimation,
              ),
              const SizedBox(height: 18),

              // 6. Key Financial Metrics Section
              ReportsMetricsGrid(
                activeTotal: activeTotal,
                totalTransactions: targetTransactions.length,
                topCategory: categoryList.isNotEmpty ? categoryList.first.name : '-',
                topCategoryPercent: categoryList.isNotEmpty && activeTotal > 0
                    ? (categoryList.first.total / activeTotal * 100)
                    : 0,
                isExpenseTab: isExpenseTab,
                selectedMonth: _selectedDate,
              ),
              const SizedBox(height: 18),

              // 7. Animated Category Breakdown List
              ReportsCategoryList(
                totalAmount: activeTotal,
                categories: categoryList,
                isExpense: isExpenseTab,
                animation: _chartAnimation,
              ),
            ] else ...[
              _buildEmptyReportState(isExpenseTab),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Pengeluaran',
              value: 'expense',
              icon: Icons.arrow_upward_rounded,
              activeColor: AppColors.expense,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Pemasukan',
              value: 'income',
              icon: Icons.arrow_downward_rounded,
              activeColor: AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required String value,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == value;

    return GestureDetector(
      onTap: () {
        if (_selectedTab != value) {
          setState(() {
            _selectedTab = value;
          });
          _animController.forward(from: 0.0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReportState(bool isExpense) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isExpense
                ? 'Belum ada pengeluaran di ${AppDateFormatter.formatMonthYear(_selectedDate)}'
                : 'Belum ada pemasukan di ${AppDateFormatter.formatMonthYear(_selectedDate)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Catat transaksi lewat Chatbot AI atau form pencatatan untuk melihat visualisasi laporan.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<double> _calculateWeeklyTotals(List<TransactionModel> transactions, bool isExpense) {
    final List<double> weeks = [0.0, 0.0, 0.0, 0.0, 0.0];
    final target = transactions.where((t) => isExpense ? t.isExpense : t.isIncome);

    for (final tx in target) {
      final day = tx.transactionDate.day;
      if (day <= 7) {
        weeks[0] += tx.amount;
      } else if (day <= 14) {
        weeks[1] += tx.amount;
      } else if (day <= 21) {
        weeks[2] += tx.amount;
      } else if (day <= 28) {
        weeks[3] += tx.amount;
      } else {
        weeks[4] += tx.amount;
      }
    }

    if (weeks[4] == 0) {
      return weeks.sublist(0, 4);
    }
    return weeks;
  }
}
