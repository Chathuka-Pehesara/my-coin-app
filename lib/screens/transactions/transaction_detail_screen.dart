import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_state_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionRecord transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to permanently delete this transaction record? This will adjust your account balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseCoral),
            onPressed: () {
              context.read<AppStateProvider>().deleteTransaction(transaction);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicate(BuildContext context) {
    context.read<AppStateProvider>().duplicateTransaction(transaction);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction duplicated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final category = state.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => state.categories.first,
    );

    final account = state.accounts.firstWhere(
      (a) => a.id == transaction.accountId,
      orElse: () => state.accounts.first,
    );

    final toAccount = transaction.toAccountId != null
        ? state.accounts.firstWhere(
            (a) => a.id == transaction.toAccountId,
            orElse: () => state.accounts.first,
          )
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Duplicate Record',
            onPressed: () => _duplicate(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Record',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(transactionToEdit: transaction),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expenseCoral, size: 20),
            tooltip: 'Delete Record',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Amount Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: transaction.type.lightColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.type.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: transaction.type.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(
                      transaction.amount,
                      currencyCode: state.currencyCode,
                      isMasked: state.isBalanceMasked,
                      showSign: transaction.type == TransactionType.income,
                    ),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: transaction.type.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metadata card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    isDark: isDark,
                    icon: Icons.calendar_today_outlined,
                    label: 'Date & Time',
                    value: '${AppDateUtils.formatFull(transaction.date)} at ${AppDateUtils.formatTime(transaction.date)}',
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    isDark: isDark,
                    icon: category.icon,
                    iconColor: category.color,
                    label: 'Category',
                    value: category.name,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    isDark: isDark,
                    icon: account.icon,
                    iconColor: account.color,
                    label: transaction.type == TransactionType.transfer ? 'Source Account' : 'Account',
                    value: account.name,
                  ),
                  if (toAccount != null) ...[
                    _buildDivider(isDark),
                    _buildDetailRow(
                      isDark: isDark,
                      icon: toAccount.icon,
                      iconColor: toAccount.color,
                      label: 'Destination Account',
                      value: toAccount.name,
                    ),
                  ],
                  if (transaction.merchant != null && transaction.merchant!.isNotEmpty) ...[
                    _buildDivider(isDark),
                    _buildDetailRow(
                      isDark: isDark,
                      icon: Icons.storefront_outlined,
                      label: 'Merchant',
                      value: transaction.merchant!,
                    ),
                  ],
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    _buildDivider(isDark),
                    _buildDetailRow(
                      isDark: isDark,
                      icon: Icons.notes_rounded,
                      label: 'Note',
                      value: transaction.note!,
                    ),
                  ],
                  if (transaction.isRecurring) ...[
                    _buildDivider(isDark),
                    _buildDetailRow(
                      isDark: isDark,
                      icon: Icons.sync_rounded,
                      label: 'Recurring',
                      value: 'Generated from recurring schedule',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.goldDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
    );
  }
}
