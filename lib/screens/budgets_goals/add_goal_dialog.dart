import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../providers/app_state_provider.dart';

class AddGoalDialog extends StatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddGoalDialog({super.key, this.goalToEdit});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _initialSavedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _targetDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      final g = widget.goalToEdit!;
      _nameController.text = g.name;
      _targetAmountController.text = g.targetAmount.toStringAsFixed(2);
      _initialSavedController.text = g.currentAmount.toStringAsFixed(2);
      _noteController.text = g.note ?? '';
      _targetDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _initialSavedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a goal name');
      return;
    }

    final targetAmount = double.tryParse(_targetAmountController.text.trim());
    if (targetAmount == null || targetAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid target amount');
      return;
    }

    final currentAmount = double.tryParse(_initialSavedController.text.trim()) ?? 0.0;
    final state = context.read<AppStateProvider>();

    if (widget.goalToEdit != null) {
      final updated = widget.goalToEdit!.copyWith(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      state.saveSavingsGoal(updated);
    } else {
      final newGoal = SavingsGoal(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        iconCode: Icons.savings_outlined.codePoint,
        colorValue: 0xFF0F867C,
      );
      state.saveSavingsGoal(newGoal);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.goalToEdit != null ? 'Edit Savings Goal' : 'New Savings Goal',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name *',
                hintText: 'e.g., Emergency Fund, Vacation, Car',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _targetAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Amount (${state.currencyCode}) *',
                hintText: 'e.g., 500000',
                prefixIcon: const Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _initialSavedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Already Saved Amount (${state.currencyCode})',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Target Date Picker
            InkWell(
              onTap: _pickTargetDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.goldDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _targetDate != null
                            ? 'Target Date: ${DateFormat('MMM d, yyyy').format(_targetDate!)}'
                            : 'Select Target Date (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _targetDate != null
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: const Icon(Icons.clear, size: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Why this goal matters',
                prefixIcon: Icon(Icons.notes_rounded),
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
          child: Text(widget.goalToEdit != null ? 'Update Goal' : 'Create Goal'),
        ),
      ],
    );
  }
}
