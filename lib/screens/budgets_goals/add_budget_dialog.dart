import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/app_state_provider.dart';

class AddBudgetDialog extends StatefulWidget {
  final Budget? budgetToEdit;

  const AddBudgetDialog({super.key, this.budgetToEdit});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategoryId; // null = overall monthly budget
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _amountController.text = widget.budgetToEdit!.limitAmount.toStringAsFixed(2);
      _selectedCategoryId = widget.budgetToEdit!.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive budget amount');
      return;
    }

    final now = DateTime.now();
    final state = context.read<AppStateProvider>();

    if (widget.budgetToEdit != null) {
      final updated = widget.budgetToEdit!.copyWith(
        limitAmount: amount,
        categoryId: _selectedCategoryId,
      );
      state.saveBudget(updated);
    } else {
      final id = 'bgt_${_selectedCategoryId ?? 'overall'}_${now.month}_${now.year}';
      final newBudget = Budget(
        id: id,
        categoryId: _selectedCategoryId,
        limitAmount: amount,
        month: now.month,
        year: now.year,
      );
      state.saveBudget(newBudget);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final expenseCategories = state.categories.where((c) => c.type == CategoryType.expense).toList();

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.budgetToEdit != null ? 'Edit Budget' : 'Set New Budget',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set spending boundaries for the entire month or allocate specific limits to categories.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Scope Selector
            DropdownButtonFormField<String?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Budget Scope',
                prefixIcon: Icon(Icons.tune_rounded),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Overall Monthly Total Budget', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...expenseCategories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 16, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.name, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Limit Amount (${state.currencyCode}) *',
                hintText: 'e.g. 50000',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.expenseCoral, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Budget'),
        ),
      ],
    );
  }
}
