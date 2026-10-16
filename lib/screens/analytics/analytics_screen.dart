import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_record.dart';
import '../../models/category.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/spending_heatmap.dart';
import 'what_if_simulator_sheet.dart';

enum AnalyticsPeriod {
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
  allTime;

  String get displayName {
    switch (this) {
      case AnalyticsPeriod.thisMonth:
        return 'This Month';
      case AnalyticsPeriod.lastMonth:
        return 'Last Month';
      case AnalyticsPeriod.thisQuarter:
        return 'Quarter';
      case AnalyticsPeriod.thisYear:
        return 'Year';
      case AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.thisMonth;
  int _touchedPieIndex = -1;

  List<TransactionRecord> _filterTransactionsByPeriod(List<TransactionRecord> list) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case AnalyticsPeriod.thisMonth:
        return list.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
      case AnalyticsPeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        return list.where((t) => t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month).toList();
      case AnalyticsPeriod.thisQuarter:
        final currentQuarter = ((now.month - 1) / 3).floor();
        return list.where((t) => t.date.year == now.year && ((t.date.month - 1) / 3).floor() == currentQuarter).toList();
      case AnalyticsPeriod.thisYear:
        return list.where((t) => t.date.year == now.year).toList();
      case AnalyticsPeriod.allTime:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final periodTransactions = _filterTransactionsByPeriod(state.transactions);

    final totalIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    final totalCashflow = totalIncome + totalExpense;
    final incomePercent = totalCashflow > 0 ? (totalIncome / totalCashflow) * 100 : 0.0;
    final expensePercent = totalCashflow > 0 ? (totalExpense / totalCashflow) * 100 : 0.0;

    // Category Expense Breakdown
    final categoryTotals = <String, double>{};
    for (final tx in periodTransactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0.0) + tx.amount;
    }

    final sortedCategoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily spending calculation for average
    final now = DateTime.now();
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day.clamp(1, daysInCurrentMonth);
    final avgDailySpend = totalExpense / currentDay;

    // Largest expenses in period
    final largestExpenses = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph_rounded, color: AppColors.goldDark),
            tooltip: 'What-If Budget Simulator',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const FractionallySizedBox(
                  heightFactor: 0.9,
                  child: WhatIfSimulatorSheet(),
                ),
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
            // Period Selector Tabs
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
                children: AnalyticsPeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.darkSurfaceElevated : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            period.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.goldLight : AppColors.goldDark)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricTile(
                        isDark: isDark,
                        label: 'Income',
                        amount: totalIncome,
                        color: AppColors.incomeGreen,
                        currencyCode: state.currencyCode,
                        isMasked: state.isBalanceMasked,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      Container(height: 40, width: 1, color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
                      _buildMetricTile(
                        isDark: isDark,
                        label: 'Expenses',
                        amount: totalExpense,
                        color: AppColors.expenseCoral,
                        currencyCode: state.currencyCode,
                        isMasked: state.isBalanceMasked,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      Container(height: 40, width: 1, color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
                      _buildMetricTile(
                        isDark: isDark,
                        label: 'Net Flow',
                        amount: netSavings,
                        color: netSavings >= 0 ? AppColors.incomeGreen : AppColors.expenseCoral,
                        currencyCode: state.currencyCode,
                        isMasked: state.isBalanceMasked,
                        icon: Icons.savings_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: savingsRate >= 0 ? AppColors.incomeGreen : AppColors.expenseCoral,
                        ),
                      ),
                      Text(
                        'Avg Daily Spend: ${CurrencyFormatter.format(avgDailySpend, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked, decimalDigits: 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // GitHub-Style Spending Intensity Heatmap
            const SpendingHeatmapCard(),
            const SizedBox(height: 24),

            // Bar Chart: Cash Flow Comparison (Income vs Expense)
            Text(
              'Income vs. Expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 245,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: ((totalIncome > totalExpense ? totalIncome : totalExpense) * 1.35 + 1000),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = groupIndex == 0;
                        final percent = isIncome ? incomePercent : expensePercent;
                        return BarTooltipItem(
                          '${isIncome ? 'Income' : 'Expense'} (${percent.toStringAsFixed(1)}%)\n${CurrencyFormatter.format(rod.toY, currencyCode: state.currencyCode, decimalDigits: 0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.incomeGreen)),
                            );
                          } else if (val.toInt() == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.expenseCoral)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.incomeGreenLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.incomeGreen.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${incomePercent.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                                ),
                              ),
                            );
                          } else if (val.toInt() == 1) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.expenseCoralLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.expenseCoral.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${expensePercent.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.expenseCoral),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: totalIncome,
                          color: AppColors.incomeGreen,
                          width: 42,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: totalExpense,
                          color: AppColors.expenseCoral,
                          width: 42,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Donut Chart: Expense Breakdown by Category
            Text(
              'Expense by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: sortedCategoryEntries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No expense data recorded for this period.')),
                    )
                  : Builder(
                      builder: (context) {
                        String centerCategoryTitle = 'Total Expenses';
                        String centerCategoryPercent = '100%';
                        String centerCategoryAmount = CurrencyFormatter.format(
                          totalExpense,
                          currencyCode: state.currencyCode,
                          isMasked: state.isBalanceMasked,
                          decimalDigits: 0,
                        );

                        if (_touchedPieIndex >= 0 && _touchedPieIndex < sortedCategoryEntries.length) {
                          final activeEntry = sortedCategoryEntries[_touchedPieIndex];
                          final activeCategory = state.categories.firstWhere(
                            (c) => c.id == activeEntry.key,
                            orElse: () => Category(id: '', name: 'Other', type: CategoryType.expense, iconCode: 0, colorValue: 0xFFC5A059),
                          );
                          centerCategoryTitle = activeCategory.name;
                          final p = totalExpense > 0 ? (activeEntry.value / totalExpense) * 100 : 0.0;
                          centerCategoryPercent = '${p.toStringAsFixed(1)}%';
                          centerCategoryAmount = CurrencyFormatter.format(
                            activeEntry.value,
                            currencyCode: state.currencyCode,
                            isMasked: state.isBalanceMasked,
                            decimalDigits: 0,
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event.isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse.touchedSection == null) {
                                              _touchedPieIndex = -1;
                                              return;
                                            }
                                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 52,
                                      sections: List.generate(sortedCategoryEntries.length, (i) {
                                        final entry = sortedCategoryEntries[i];
                                        final isTouched = i == _touchedPieIndex;
                                        final radius = isTouched ? 56.0 : 46.0;
                                        final category = state.categories.firstWhere(
                                          (c) => c.id == entry.key,
                                          orElse: () => Category(id: '', name: 'Other', type: CategoryType.expense, iconCode: 0, colorValue: 0xFFC5A059),
                                        );
                                        final percentage = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;

                                        return PieChartSectionData(
                                          color: category.color,
                                          value: entry.value,
                                          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '${percentage.toStringAsFixed(0)}%',
                                          radius: radius,
                                          titleStyle: TextStyle(
                                            fontSize: isTouched ? 12 : 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Center Hole Interactive Inspector
                                  IgnorePointer(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            centerCategoryTitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          centerCategoryPercent,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.goldPrimary,
                                          ),
                                        ),
                                        Text(
                                          centerCategoryAmount,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Category Interactive Legend & Drilldown List
                            ...List.generate(sortedCategoryEntries.length, (i) {
                              final entry = sortedCategoryEntries[i];
                              final category = state.categories.firstWhere(
                                (c) => c.id == entry.key,
                                orElse: () => Category(id: '', name: 'Other', type: CategoryType.expense, iconCode: 0, colorValue: 0xFFC5A059),
                              );
                              final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                              final isSelected = i == _touchedPieIndex;

                              return InkWell(
                                onTap: () {
                                  setState(() => _touchedPieIndex = (_touchedPieIndex == i ? -1 : i));
                                  final catTransactions = periodTransactions
                                      .where((t) => t.type == TransactionType.expense && t.categoryId == entry.key)
                                      .toList();
                                  _showCategoryTransactionsSheet(
                                    context,
                                    category,
                                    catTransactions,
                                    state.currencyCode,
                                    state.isBalanceMasked,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (category.color.withValues(alpha: isDark ? 0.2 : 0.12))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: category.color.withValues(alpha: 0.5))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: category.color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(category.icon, size: 15, color: category.color),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${percent.toStringAsFixed(1)}% of total expenses',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(entry.value, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Largest Transactions in this period
            Text(
              'Largest Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: largestExpenses.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No expense records in this range.')))
                  : Column(
                      children: largestExpenses.take(4).map((tx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      AppDateUtils.formatMedium(tx.date),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(tx.amount, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expenseCoral,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String label,
    required double amount,
    required Color color,
    required String currencyCode,
    required bool isMasked,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount, currencyCode: currencyCode, isMasked: isMasked, decimalDigits: 0),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showCategoryTransactionsSheet(
    BuildContext context,
    Category category,
    List<TransactionRecord> transactions,
    String currencyCode,
    bool isMasked,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon, size: 20, color: category.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${transactions.length} transactions in this period',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      transactions.fold(0.0, (s, t) => s + t.amount),
                      currencyCode: currencyCode,
                      isMasked: isMasked,
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.expenseCoral),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No transactions recorded for this category.')),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (_, idx) {
                      final tx = transactions[idx];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (tx.merchant != null && tx.merchant!.isNotEmpty)
                                  Text(
                                    tx.merchant!,
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '-${CurrencyFormatter.format(tx.amount, currencyCode: currencyCode, isMasked: isMasked)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.expenseCoral),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
