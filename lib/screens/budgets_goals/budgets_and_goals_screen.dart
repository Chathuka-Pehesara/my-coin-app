import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/empty_state_view.dart';
import 'add_budget_dialog.dart';
import 'add_goal_dialog.dart';
import 'goal_contribution_dialog.dart';
import '../../widgets/coin_drop_modal.dart';

class BudgetsAndGoalsScreen extends StatelessWidget {
  const BudgetsAndGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
        appBar: AppBar(
          title: const Text('Plans & Commitments'),
          bottom: TabBar(
            labelColor: isDark ? AppColors.goldLight : AppColors.goldDark,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.goldPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Budgets'),
              Tab(text: 'Savings Goals'),
              Tab(text: 'Recurring'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BudgetsTabView(),
            _SavingsGoalsTabView(),
            _RecurringTabView(),
          ],
        ),
      ),
    );
  }
}

// ================= BUDGETS TAB =================
class _BudgetsTabView extends StatelessWidget {
  const _BudgetsTabView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final budgets = state.budgets;
    final monthlyExpenses = state.currentMonthExpenses;
    final categoryBreakdown = state.categoryExpenseBreakdown;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budgets (${DateFormat('MMMM yyyy').format(DateTime.now())})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddBudgetDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Set Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (budgets.isEmpty)
            EmptyStateView(
              icon: Icons.track_changes_rounded,
              title: 'No Budgets Configured',
              message: 'Establish monthly limits to prevent overspending and stay financially disciplined.',
              actionLabel: 'Set Monthly Budget',
              onAction: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddBudgetDialog(),
                );
              },
            )
          else
            ...budgets.map((b) {
              final isOverall = b.isOverall;
              final spent = isOverall ? monthlyExpenses : (categoryBreakdown[b.categoryId] ?? 0.0);
              final limit = b.limitAmount;
              final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
              final remaining = limit - spent;

              Color progressColor = AppColors.incomeGreen;
              String statusLabel = 'On Track';
              if (ratio >= 1.0) {
                progressColor = AppColors.expenseCoral;
                statusLabel = 'Exceeded';
              } else if (ratio >= 0.8) {
                progressColor = Colors.orange;
                statusLabel = 'Near Limit';
              }

              final categoryName = isOverall
                  ? 'Overall Monthly Budget'
                  : state.categories.firstWhere((c) => c.id == b.categoryId, orElse: () => state.categories.first).name;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: progressColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
                          onSelected: (val) {
                            if (val == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => AddBudgetDialog(budgetToEdit: b),
                              );
                            } else if (val == 'delete') {
                              state.deleteBudget(b.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Limit', style: TextStyle(fontSize: 12))),
                            const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.expenseCoral))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (ratio > 1.0) ? 1.0 : ratio,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ${CurrencyFormatter.format(spent, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Remaining: ${CurrencyFormatter.format(remaining, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: remaining >= 0 ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary) : AppColors.expenseCoral,
                          ),
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
    );
  }
}

// ================= SAVINGS GOALS TAB =================
class _SavingsGoalsTabView extends StatelessWidget {
  const _SavingsGoalsTabView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final goals = state.savingsGoals;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Goals (${goals.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddGoalDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (goals.isEmpty)
            EmptyStateView(
              icon: Icons.savings_outlined,
              title: 'No Goals Created',
              message: 'Build targets for emergency funds, tech upgrades, or travel dreams.',
              actionLabel: 'Create First Goal',
              onAction: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddGoalDialog(),
                );
              },
            )
          else
            ...goals.map((g) {
              final percent = (g.progressRatio * 100).toStringAsFixed(0);
              final monthlyRecommendation = g.recommendedMonthlyContribution;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: g.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(g.icon, size: 22, color: g.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              if (g.targetDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${DateFormat('MMM yyyy').format(g.targetDate!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: g.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.progressRatio,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(g.color),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved: ${CurrencyFormatter.format(g.currentAmount, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Target: ${CurrencyFormatter.format(g.targetAmount, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    if (monthlyRecommendation != null && monthlyRecommendation > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.savingsTealLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.savingsTeal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Recommended: save ${CurrencyFormatter.format(monthlyRecommendation, currencyCode: state.currencyCode, decimalDigits: 0)}/month to reach on time.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.savingsTeal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => CoinDropModal(goal: g),
                              );
                            },
                            icon: const Icon(Icons.toll_rounded, size: 15, color: Colors.white),
                            label: const Text('Drop Coins ✨', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => GoalContributionDialog(goal: g, isDeposit: true),
                            );
                          },
                          child: const Text('Add', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textTertiary),
                          tooltip: 'Withdraw Funds',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => GoalContributionDialog(goal: g, isDeposit: false),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: AppColors.expenseCoral),
                          tooltip: 'Delete Goal',
                          onPressed: () => state.deleteSavingsGoal(g.id),
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
    );
  }
}

// ================= RECURRING TAB =================
class _RecurringTabView extends StatelessWidget {
  const _RecurringTabView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final recurringList = state.recurringTransactions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedules & Subscriptions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recurringList.isEmpty)
            const EmptyStateView(
              icon: Icons.sync_rounded,
              title: 'No Recurring Schedules',
              message: 'Track recurring salaries, rent, fiber subscriptions, and utility payments.',
            )
          else
            ...recurringList.map((rec) {
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rec.type.lightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(rec.type.icon, size: 20, color: rec.type.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${rec.frequency.displayName} • Next: ${DateFormat('MMM d, yyyy').format(rec.nextDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(rec.amount, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: rec.type.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            state.executeRecurringNow(rec);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Recorded "${rec.title}" into transactions.')),
                            );
                          },
                          child: const Text('Process Now', style: TextStyle(fontSize: 11)),
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
    );
  }
}
