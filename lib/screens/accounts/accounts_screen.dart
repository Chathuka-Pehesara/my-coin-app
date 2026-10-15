import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/account.dart';
import '../../providers/app_state_provider.dart';
import 'add_edit_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final accounts = state.accounts;

    // Financial breakdown
    final totalAssets = accounts
        .where((a) => a.balance > 0 && a.isIncludedInTotal)
        .fold(0.0, (sum, a) => sum + a.balance);

    final totalLiabilities = accounts
        .where((a) => a.balance < 0 && a.isIncludedInTotal)
        .fold(0.0, (sum, a) => sum + a.balance.abs());

    final netWorth = totalAssets - totalLiabilities;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Account',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditAccountDialog(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth Summary Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 8),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL NET WORTH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(
                      netWorth,
                      currencyCode: state.currencyCode,
                      isMasked: state.isBalanceMasked,
                    ),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // Assets
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.incomeGreenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assets',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.incomeGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalAssets,
                                  currencyCode: state.currencyCode,
                                  isMasked: state.isBalanceMasked,
                                  decimalDigits: 0,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.incomeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Liabilities
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.expenseCoralLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Liabilities / Cards',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.expenseCoral,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalLiabilities,
                                  currencyCode: state.currencyCode,
                                  isMasked: state.isBalanceMasked,
                                  decimalDigits: 0,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.expenseCoral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Accounts List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected Accounts (${accounts.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddEditAccountDialog(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...accounts.map((acc) {
              final isNegative = acc.balance < 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: acc.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: acc.color.withAlpha(60)),
                      ),
                      child: Icon(acc.icon, color: acc.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                acc.type.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              if (!acc.isIncludedInTotal) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Excluded', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            acc.balance,
                            currencyCode: state.currencyCode,
                            isMasked: state.isBalanceMasked,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isNegative
                                ? AppColors.expenseCoral
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textTertiary),
                          onSelected: (action) {
                            if (action == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditAccountDialog(accountToEdit: acc),
                              );
                            } else if (action == 'delete') {
                              _confirmDeleteAccount(context, acc);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Account', style: TextStyle(fontSize: 13))),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Account', style: TextStyle(fontSize: 13, color: AppColors.expenseCoral)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete "${account.name}"?'),
        content: const Text(
          'Are you sure you want to remove this account? Existing transactions assigned to it will remain in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseCoral),
            onPressed: () {
              context.read<AppStateProvider>().deleteAccount(account.id);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
