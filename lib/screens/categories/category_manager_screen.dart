import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category.dart';
import '../../providers/app_state_provider.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([Category? categoryToEdit]) {
    showDialog(
      context: context,
      builder: (_) => _AddEditCategoryDialog(
        categoryToEdit: categoryToEdit,
        initialType: _tabController.index == 0 ? CategoryType.expense : CategoryType.income,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final expenseCategories = state.categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = state.categories.where((c) => c.type == CategoryType.income).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.goldLight : AppColors.goldDark,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Expense Categories'),
            Tab(text: 'Income Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenseCategories, isDark, state),
          _buildCategoryList(incomeCategories, isDark, state),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: AppColors.textOnGold,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, bool isDark, AppStateProvider state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.color.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cat.color.withAlpha(60)),
                ),
                child: Icon(cat.icon, size: 20, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      cat.isDefault ? 'Default System Category' : 'Custom Category',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textTertiary),
                onSelected: (action) async {
                  if (action == 'edit') {
                    _showAddEditDialog(cat);
                  } else if (action == 'delete') {
                    final deleted = await state.deleteCategory(cat.id);
                    if (!deleted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot delete category: existing transactions reference it. Please reassign those transactions first.'),
                          backgroundColor: AppColors.expenseCoral,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.expenseCoral)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddEditCategoryDialog extends StatefulWidget {
  final Category? categoryToEdit;
  final CategoryType initialType;

  const _AddEditCategoryDialog({this.categoryToEdit, required this.initialType});

  @override
  State<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<_AddEditCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  late CategoryType _type;
  int _selectedColor = 0xFFC5A059;
  int _selectedIconCode = 0xe532; // Default restaurant/category

  final List<int> _palette = [
    0xFFC5A059, // Gold
    0xFF2D8A4E, // Sage green
    0xFF3F77B0, // Blue
    0xFF8860B8, // Lavender
    0xFFD34541, // Coral red
    0xFF0F867C, // Teal
    0xFFD9822B, // Orange
    0xFFE91E63, // Pink
  ];

  final List<IconData> _iconList = [
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.home,
    Icons.lightbulb,
    Icons.movie,
    Icons.local_hospital,
    Icons.school,
    Icons.subscriptions,
    Icons.flight,
    Icons.fitness_center,
    Icons.coffee,
    Icons.pets,
    Icons.card_giftcard,
    Icons.work,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      final c = widget.categoryToEdit!;
      _nameController.text = c.name;
      _type = c.type;
      _selectedColor = c.colorValue;
      _selectedIconCode = c.iconCode;
    } else {
      _type = widget.initialType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final state = context.read<AppStateProvider>();
    if (widget.categoryToEdit != null) {
      final updated = widget.categoryToEdit!.copyWith(
        name: name,
        type: _type,
        colorValue: _selectedColor,
        iconCode: _selectedIconCode,
      );
      state.saveCategory(updated);
    } else {
      final newCat = Category(
        id: 'cat_custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _type,
        iconCode: _selectedIconCode,
        colorValue: _selectedColor,
      );
      state.saveCategory(newCat);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.categoryToEdit != null ? 'Edit Category' : 'New Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Subscriptions, Books',
              ),
            ),
            const SizedBox(height: 16),

            // Icon selector
            const Text('Choose Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconList.map((icon) {
                final isSelected = _selectedIconCode == icon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.goldSubtle : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.goldPrimary : Colors.transparent),
                    ),
                    child: Icon(icon, size: 20, color: isSelected ? AppColors.goldDark : AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color selector
            const Text('Choose Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _palette.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
