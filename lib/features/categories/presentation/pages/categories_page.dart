import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context, bool isExpenseDefault) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    bool isExpense = isExpenseDefault;
    String selectedColor = '#0D9488';

    final colors = [
      '#0D9488', // Teal
      '#EF4444', // Red
      '#F97316', // Orange
      '#F59E0B', // Amber
      '#10B981', // Emerald
      '#06B6D4', // Cyan
      '#3B82F6', // Blue
      '#6366F1', // Indigo
      '#8B5CF6', // Purple
      '#EC4899', // Pink
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Tambah Kategori Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle Type
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => isExpense = true),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isExpense
                                        ? AppColors.expense
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                        color: isExpense
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => isExpense = false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isExpense
                                        ? AppColors.income
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                        color: !isExpense
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kategori',
                          hintText: 'Contoh: Skincare / Kucing / Sedekah',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama kategori tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Color Picker
                      const Text(
                        'Pilih Warna:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((colorHex) {
                          final color = Color(int.parse(
                              colorHex.replaceAll('#', '0xFF')));
                          final isSelected = selectedColor == colorHex;

                          return GestureDetector(
                            onTap: () => setDialogState(
                                () => selectedColor = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primaryDark,
                                        width: 3)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final provider = context.read<CategoryProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(dialogContext);

                      final success = await provider.createCategory(
                        name: nameController.text.trim(),
                        type: isExpense ? 'expense' : 'income',
                        color: selectedColor,
                      );

                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Kategori berhasil ditambahkan!'
                              : 'Gagal menambah kategori'),
                          backgroundColor:
                              success ? AppColors.income : AppColors.expense,
                        ),
                      );
                    },
                    child: const Text('Simpan'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: catProvider.isLoading && catProvider.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(catProvider.expenseCategories),
                _buildCategoryList(catProvider.incomeCategories),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(
            context, _tabController.index == 0),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('Belum ada kategori'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = cat.colorValue;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cat.iconData,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: cat.isDefault
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Bawaan',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Kustom',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.expense),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hapus Kategori',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Hapus Kategori'),
                              content: Text(
                                  'Apakah Anda yakin ingin menghapus kategori "${cat.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.expense),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            final success = await context
                                .read<CategoryProvider>()
                                .deleteCategory(cat.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Kategori "${cat.name}" berhasil dihapus'
                                      : 'Gagal menghapus kategori'),
                                  backgroundColor: success
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
