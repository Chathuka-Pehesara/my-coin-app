import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../providers/app_state_provider.dart';

class GoalContributionDialog extends StatefulWidget {
  final SavingsGoal goal;
  final bool isDeposit;

  const GoalContributionDialog({
    super.key,
    required this.goal,
    required this.isDeposit,
  });

  @override
  State<GoalContributionDialog> createState() => _GoalContributionDialogState();
}

class _GoalContributionDialogState extends State<GoalContributionDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedAccountId;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    final state = context.read<AppStateProvider>();
    final accountId = _selectedAccountId ?? (state.accounts.isNotEmpty ? state.accounts.first.id : '');
    if (accountId.isEmpty) {
      setState(() => _errorMessage = 'Please choose an account');
      return;
    }

    if (widget.isDeposit) {
      state.depositToGoal(
        goal: widget.goal,
        amount: amount,
        fromAccountId: accountId,
      );
    } else {
      state.withdrawFromGoal(
        goal: widget.goal,
        amount: amount,
        toAccountId: accountId,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    if (_selectedAccountId == null && state.accounts.isNotEmpty) {
      _selectedAccountId = state.accounts.first.id;
    }

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isDeposit ? 'Add to "${widget.goal.name}"' : 'Withdraw from "${widget.goal.name}"',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDeposit
                  ? 'Transfer funds from one of your accounts to increase your savings progress.'
                  : 'Withdraw accumulated funds from this goal back into your account.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount (${state.currencyCode}) *',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: InputDecoration(
                labelText: widget.isDeposit ? 'Deduct from Account' : 'Deposit into Account',
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              items: state.accounts.map((a) {
                return DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedAccountId = val);
              },
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
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDeposit ? AppColors.savingsTeal : AppColors.goldPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(widget.isDeposit ? 'Deposit' : 'Withdraw'),
        ),
      ],
    );
  }
}
