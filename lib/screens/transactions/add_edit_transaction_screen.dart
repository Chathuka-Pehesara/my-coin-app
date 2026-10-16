import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_record.dart';
import '../../models/category.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/coin_character_dialog.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionRecord? transactionToEdit;
  final TransactionType initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  late TransactionType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedToAccountId;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final editTx = widget.transactionToEdit;
    if (editTx != null) {
      _selectedType = editTx.type;
      _amountController.text = editTx.amount.toStringAsFixed(2);
      _titleController.text = editTx.title;
      _merchantController.text = editTx.merchant ?? '';
      _noteController.text = editTx.note ?? '';
      _selectedDate = editTx.date;
      _selectedTime = TimeOfDay.fromDateTime(editTx.date);
      _selectedCategoryId = editTx.categoryId;
      _selectedAccountId = editTx.accountId;
      _selectedToAccountId = editTx.toAccountId;
    } else {
      _selectedType = widget.initialType;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive amount.');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a description or title.');
      return;
    }

    final state = context.read<AppStateProvider>();
    final accountId = _selectedAccountId ?? (state.accounts.isNotEmpty ? state.accounts.first.id : '');
    if (accountId.isEmpty) {
      setState(() => _errorMessage = 'Please select an account.');
      return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (_selectedToAccountId == null || _selectedToAccountId == accountId) {
        setState(() => _errorMessage = 'Destination account must be different from source account.');
        return;
      }
    }

    final categoryId = _selectedCategoryId ??
        (state.categories.isNotEmpty ? state.categories.first.id : 'cat_other_expense');

    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    TransactionRecord savedTx;
    if (widget.transactionToEdit != null) {
      savedTx = widget.transactionToEdit!.copyWith(
        title: title,
        amount: amount,
        type: _selectedType,
        date: fullDateTime,
        categoryId: categoryId,
        accountId: accountId,
        toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccountId : null,
        merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      await state.updateTransaction(savedTx, widget.transactionToEdit!);
    } else {
      savedTx = TransactionRecord(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        amount: amount,
        type: _selectedType,
        date: fullDateTime,
        categoryId: categoryId,
        accountId: accountId,
        toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccountId : null,
        merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );
      await state.addTransaction(savedTx);
    }

    if (mounted) {
      await CoinCharacterReactionModal.show(
        context,
        transaction: savedTx,
        currencyCode: state.currencyCode,
        isMasked: state.isBalanceMasked,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final currencyInfo = CurrencyFormatter.getCurrencyInfo(state.currencyCode);

    // Available categories by type
    final availableCategories = state.categories.where((c) {
      if (_selectedType == TransactionType.income) {
        return c.type == CategoryType.income;
      } else {
        return c.type == CategoryType.expense;
      }
    }).toList();

    if (_selectedCategoryId == null && availableCategories.isNotEmpty) {
      _selectedCategoryId = availableCategories.first.id;
    }

    if (_selectedAccountId == null && state.accounts.isNotEmpty) {
      _selectedAccountId = state.accounts.first.id;
    }

    if (_selectedType == TransactionType.transfer && _selectedToAccountId == null && state.accounts.length > 1) {
      _selectedToAccountId = state.accounts.firstWhere((a) => a.id != _selectedAccountId).id;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: Text(widget.transactionToEdit != null ? 'Edit Record' : 'Add Transaction'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.goldDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selector Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  _buildTypeTab(TransactionType.expense, 'Expense', AppColors.expenseCoral),
                  _buildTypeTab(TransactionType.income, 'Income', AppColors.incomeGreen),
                  _buildTypeTab(TransactionType.transfer, 'Transfer', AppColors.transferBlue),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMOUNT (${currencyInfo.code})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currencyInfo.symbol,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _selectedType.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: widget.transactionToEdit == null,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            hintText: '0.00',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description / Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Description *',
                hintText: 'e.g., Grocery shopping, Client fee, Rent',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector (If not transfer)
            if (_selectedType != TransactionType.transfer) ...[
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    items: availableCategories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: c.color.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(c.icon, size: 16, color: c.color),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Account selection
            Text(
              _selectedType == TransactionType.transfer ? 'From Account' : 'Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAccountId,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items: state.accounts.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(a.icon, size: 18, color: a.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(a.balance, currencyCode: state.currencyCode),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccountId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Account (for transfer)
            if (_selectedType == TransactionType.transfer) ...[
              Text(
                'To Account',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedToAccountId,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    items: state.accounts.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Row(
                          children: [
                            Icon(a.icon, size: 18, color: a.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(a.balance, currencyCode: state.currencyCode),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedToAccountId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date and Time Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
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
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
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
                          const Icon(Icons.access_time_outlined, size: 18, color: AppColors.goldDark),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Merchant
            if (_selectedType != TransactionType.transfer) ...[
              TextField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Payee (Optional)',
                  hintText: 'e.g., Keells Super, Uber, Dialog',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add extra context or receipt note',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expenseCoralLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.expenseCoral, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.expenseCoral,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  widget.transactionToEdit != null ? 'Update Record' : 'Record Transaction',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(TransactionType type, String label, Color activeColor) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _errorMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
