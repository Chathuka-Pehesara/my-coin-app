import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/account.dart';
import '../../providers/app_state_provider.dart';

class AddEditAccountDialog extends StatefulWidget {
  final Account? accountToEdit;

  const AddEditAccountDialog({super.key, this.accountToEdit});

  @override
  State<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<AddEditAccountDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.bank;
  bool _includeInTotal = true;
  int _selectedColorValue = 0xFFC5A059;
  String? _errorMessage;

  final List<int> _colorOptions = [
    0xFFC5A059, // Gold
    0xFF2D8A4E, // Green
    0xFF3F77B0, // Blue
    0xFF0F867C, // Teal
    0xFF8860B8, // Purple
    0xFFD34541, // Red
    0xFFD9822B, // Orange
    0xFF7A8B99, // Gray
  ];

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      final acc = widget.accountToEdit!;
      _nameController.text = acc.name;
      _balanceController.text = acc.balance.toStringAsFixed(2);
      _selectedType = acc.type;
      _includeInTotal = acc.isIncludedInTotal;
      _selectedColorValue = acc.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter an account name');
      return;
    }

    final balanceText = _balanceController.text.trim();
    final balance = double.tryParse(balanceText) ?? 0.0;

    final state = context.read<AppStateProvider>();

    if (widget.accountToEdit != null) {
      final updated = widget.accountToEdit!.copyWith(
        name: name,
        type: _selectedType,
        balance: balance,
        isIncludedInTotal: _includeInTotal,
        colorValue: _selectedColorValue,
      );
      state.saveAccount(updated);
    } else {
      final newAcc = Account(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _selectedType,
        balance: balance,
        currency: state.currencyCode,
        isIncludedInTotal: _includeInTotal,
        colorValue: _selectedColorValue,
        iconCode: _selectedType.defaultIcon.codePoint,
      );
      state.saveAccount(newAcc);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.accountToEdit != null ? 'Edit Account' : 'New Account',
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
                labelText: 'Account Name *',
                hintText: 'e.g., Commercial Bank, Cash Wallet',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.defaultIcon, size: 18),
                      const SizedBox(width: 8),
                      Text(type.displayName, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: widget.accountToEdit != null ? 'Current Balance' : 'Opening Balance',
                hintText: '0.00 (use negative for credit debt)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // Color picker row
            Text(
              'Color Tag',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((cVal) {
                final isSelected = _selectedColorValue == cVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = cVal),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(cVal),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(cVal).withAlpha(120),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include in Total Net Worth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _includeInTotal,
              activeThumbColor: AppColors.goldPrimary,
              onChanged: (val) => setState(() => _includeInTotal = val),
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
          child: Text(widget.accountToEdit != null ? 'Save Changes' : 'Create Account'),
        ),
      ],
    );
  }
}
