import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/coin_avatar.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToBudgets;
  final VoidCallback onNavigateToAnalytics;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTransactions,
    required this.onNavigateToBudgets,
    required this.onNavigateToAnalytics,
  });

  void _openAddTransaction(BuildContext context, {TransactionType initialType = TransactionType.expense}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(initialType: initialType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final recentTransactions = state.transactions.take(5).toList();
    final remainingBudget = state.remainingOverallBudget;
    final overallBudget = state.currentOverallBudget;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const CoinAvatar(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Trans Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Private Personal Finance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.isBalanceMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.goldDark,
              size: 22,
            ),
            tooltip: state.isBalanceMasked ? 'Reveal balances' : 'Mask balances',
            onPressed: () => state.toggleBalanceMasking(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.goldDark, size: 22),
            tooltip: 'Settings & Data',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Balance Card
            BalanceCard(
              totalBalance: state.totalNetBalance,
              monthlyIncome: state.currentMonthIncome,
              monthlyExpenses: state.currentMonthExpenses,
              currencyCode: state.currencyCode,
              isMasked: state.isBalanceMasked,
              onToggleMask: () => state.toggleBalanceMasking(),
              onAddTransaction: () => _openAddTransaction(context),
            ),
            const SizedBox(height: 18),

            // Quick Actions Bar
            Row(
              children: [
                _buildQuickActionBtn(
                  context: context,
                  label: 'Expense',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.expenseCoral,
                  bgColor: AppColors.expenseCoralLight,
                  onTap: () => _openAddTransaction(context, initialType: TransactionType.expense),
                ),
                const SizedBox(width: 10),
                _buildQuickActionBtn(
                  context: context,
                  label: 'Income',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.incomeGreen,
                  bgColor: AppColors.incomeGreenLight,
                  onTap: () => _openAddTransaction(context, initialType: TransactionType.income),
                ),
                const SizedBox(width: 10),
                _buildQuickActionBtn(
                  context: context,
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.transferBlue,
                  bgColor: AppColors.transferBlueLight,
                  onTap: () => _openAddTransaction(context, initialType: TransactionType.transfer),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Contextual Insights Section
            if (state.insights.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 18, color: AppColors.goldDark),
                      const SizedBox(width: 6),
                      Text(
                        'Smart Financial Insights',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: onNavigateToAnalytics,
                    child: const Text('Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 114,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.insights.length,
                  itemBuilder: (context, index) {
                    final item = state.insights[index];
                    return Container(
                      width: 270,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: item.type.color.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: item.type.lightColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.type.icon, size: 14, color: item.type.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.type.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              item.message,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Monthly Budget Pacing Banner
            if (overallBudget != null) ...[
              GestureDetector(
                onTap: onNavigateToBudgets,
                child: Container(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.goldSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.track_changes_rounded, color: AppColors.goldDark, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Budget Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              remainingBudget >= 0
                                  ? '${CurrencyFormatter.format(remainingBudget, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)} remaining'
                                  : '${CurrencyFormatter.format(remainingBudget.abs(), currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)} over budget',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: remainingBudget >= 0 ? AppColors.incomeGreen : AppColors.expenseCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onNavigateToTransactions,
                  child: const Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (recentTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
                ),
                child: const Center(
                  child: Text('No transactions yet. Tap below to record your first one!'),
                ),
              )
            else
              ...recentTransactions.map((tx) {
                final category = state.categories.firstWhere(
                  (c) => c.id == tx.categoryId,
                  orElse: () => state.categories.first,
                );
                final account = state.accounts.firstWhere(
                  (a) => a.id == tx.accountId,
                  orElse: () => state.accounts.first,
                );
                final toAccount = tx.toAccountId != null
                    ? state.accounts.firstWhere(
                        (a) => a.id == tx.toAccountId,
                        orElse: () => state.accounts.first,
                      )
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionTile(
                    transaction: tx,
                    category: category,
                    account: account,
                    toAccount: toAccount,
                    currencyCode: state.currencyCode,
                    isMasked: state.isBalanceMasked,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: tx),
                        ),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
