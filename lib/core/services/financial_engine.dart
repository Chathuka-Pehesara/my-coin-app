import 'dart:math';
import '../../models/transaction_record.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/insight_item.dart';
import '../utils/currency_formatter.dart';

class FinancialEngine {
  /// Generates dynamic contextual financial insights from real transactions and budgets
  static List<InsightItem> generateInsights({
    required List<TransactionRecord> transactions,
    required List<Category> categories,
    required List<Budget> budgets,
    required String currencyCode,
  }) {
    final insights = <InsightItem>[];
    final now = DateTime.now();

    final currentMonthTxs = transactions.where((t) =>
      t.date.year == now.year && t.date.month == now.month
    ).toList();

    final previousMonthDate = DateTime(now.year, now.month - 1, 1);
    final previousMonthTxs = transactions.where((t) =>
      t.date.year == previousMonthDate.year && t.date.month == previousMonthDate.month
    ).toList();

    final currentExpenses = currentMonthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final currentIncome = currentMonthTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    // 1. Average Daily Spending & Budget Pacing
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day.clamp(1, daysInCurrentMonth);
    final avgDailySpending = currentExpenses / currentDay;

    if (currentExpenses > 0) {
      insights.add(
        InsightItem(
          id: 'insight_daily_pace',
          title: 'Daily Spending Pace',
          message: 'Your average daily spending this month is ${CurrencyFormatter.format(avgDailySpending, currencyCode: currencyCode)} per day.',
          type: InsightType.neutral,
          metricValue: avgDailySpending,
        ),
      );
    }

    // 2. Overall Budget Tracking & Projected Run-rate
    final overallBudget = budgets.firstWhere(
      (b) => b.isOverall && b.month == now.month && b.year == now.year,
      orElse: () => Budget(id: '', limitAmount: 0, month: now.month, year: now.year),
    );

    if (overallBudget.limitAmount > 0) {
      final utilization = (currentExpenses / overallBudget.limitAmount) * 100;
      final projectedTotal = avgDailySpending * daysInCurrentMonth;

      if (utilization >= 100) {
        insights.add(
          InsightItem(
            id: 'insight_budget_exceeded',
            title: 'Budget Alert',
            message: 'You have exceeded your monthly budget of ${CurrencyFormatter.format(overallBudget.limitAmount, currencyCode: currencyCode)} by ${CurrencyFormatter.format(currentExpenses - overallBudget.limitAmount, currencyCode: currencyCode)}.',
            type: InsightType.warning,
            metricValue: utilization,
          ),
        );
      } else if (projectedTotal > overallBudget.limitAmount) {
        insights.add(
          InsightItem(
            id: 'insight_budget_pacing_risk',
            title: 'Projected Budget Risk',
            message: 'At your current pace of ${CurrencyFormatter.format(avgDailySpending, currencyCode: currencyCode)}/day, you are projected to reach ${CurrencyFormatter.format(projectedTotal, currencyCode: currencyCode)}, which exceeds your budget.',
            type: InsightType.warning,
            metricValue: utilization,
          ),
        );
      } else {
        final remaining = overallBudget.limitAmount - currentExpenses;
        final daysLeft = (daysInCurrentMonth - currentDay).clamp(1, 31);
        final remainingPerDay = remaining / daysLeft;
        insights.add(
          InsightItem(
            id: 'insight_budget_healthy',
            title: 'Budget On Track',
            message: 'You have ${CurrencyFormatter.format(remaining, currencyCode: currencyCode)} remaining. Safe daily budget: ${CurrencyFormatter.format(remainingPerDay, currencyCode: currencyCode)}/day for the next $daysLeft days.',
            type: InsightType.positive,
            metricValue: utilization,
          ),
        );
      }
    }

    // 3. Category Spending Insights vs Previous Month
    final categoryExpenseMapCurrent = <String, double>{};
    for (final tx in currentMonthTxs.where((t) => t.type == TransactionType.expense)) {
      categoryExpenseMapCurrent[tx.categoryId] = (categoryExpenseMapCurrent[tx.categoryId] ?? 0.0) + tx.amount;
    }

    final categoryExpenseMapPrevious = <String, double>{};
    for (final tx in previousMonthTxs.where((t) => t.type == TransactionType.expense)) {
      categoryExpenseMapPrevious[tx.categoryId] = (categoryExpenseMapPrevious[tx.categoryId] ?? 0.0) + tx.amount;
    }

    for (final entry in categoryExpenseMapCurrent.entries) {
      final prevAmount = categoryExpenseMapPrevious[entry.key] ?? 0.0;
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(id: entry.key, name: 'Category', type: CategoryType.expense, iconCode: 0, colorValue: 0),
      );

      if (prevAmount > 0 && entry.value > 0) {
        final diffPercent = ((entry.value - prevAmount) / prevAmount) * 100;
        if (diffPercent >= 20) {
          insights.add(
            InsightItem(
              id: 'insight_cat_increase_${entry.key}',
              title: '${category.name} Spike',
              message: 'Your ${category.name} spending increased by ${diffPercent.toStringAsFixed(0)}% compared with last month (${CurrencyFormatter.format(entry.value, currencyCode: currencyCode)} vs ${CurrencyFormatter.format(prevAmount, currencyCode: currencyCode)}).',
              type: InsightType.warning,
              metricValue: diffPercent,
            ),
          );
        } else if (diffPercent <= -20) {
          insights.add(
            InsightItem(
              id: 'insight_cat_decrease_${entry.key}',
              title: '${category.name} Savings',
              message: 'Great job! Your ${category.name} expenses dropped by ${diffPercent.abs().toStringAsFixed(0)}% compared with last month.',
              type: InsightType.positive,
              metricValue: diffPercent,
            ),
          );
        }
      }
    }

    // 4. Top Spending Categories Concentration
    if (categoryExpenseMapCurrent.isNotEmpty && currentExpenses > 0) {
      final sortedEntries = categoryExpenseMapCurrent.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topThreeSum = sortedEntries.take(3).fold(0.0, (sum, e) => sum + e.value);
      final topThreePercentage = (topThreeSum / currentExpenses) * 100;

      if (sortedEntries.length >= 2) {
        final topNames = sortedEntries.take(3).map((e) {
          final cat = categories.firstWhere((c) => c.id == e.key, orElse: () => Category(id: '', name: 'General', type: CategoryType.expense, iconCode: 0, colorValue: 0));
          return cat.name;
        }).join(', ');

        insights.add(
          InsightItem(
            id: 'insight_top_concentration',
            title: 'Expense Concentration',
            message: 'Your top categories ($topNames) account for ${topThreePercentage.toStringAsFixed(0)}% of all spending this month.',
            type: topThreePercentage > 75 ? InsightType.warning : InsightType.tip,
            metricValue: topThreePercentage,
          ),
        );
      }
    }

    // 5. Net Cash Flow & Savings Rate
    if (currentIncome > 0) {
      final netSavings = currentIncome - currentExpenses;
      final savingsRate = (netSavings / currentIncome) * 100;
      if (savingsRate > 20) {
        insights.add(
          InsightItem(
            id: 'insight_high_savings_rate',
            title: 'Strong Savings Rate',
            message: 'You have retained ${savingsRate.toStringAsFixed(0)}% of your income this month (${CurrencyFormatter.format(netSavings, currencyCode: currencyCode)} saved).',
            type: InsightType.positive,
            metricValue: savingsRate,
          ),
        );
      }
    }

    // 6. Detect Statistical Outlier Transactions
    final unusualTxList = detectUnusualTransactions(transactions);
    for (final anomaly in unusualTxList.take(2)) {
      final category = categories.firstWhere(
        (c) => c.id == anomaly.categoryId,
        orElse: () => Category(id: '', name: 'General', type: CategoryType.expense, iconCode: 0, colorValue: 0),
      );

      insights.add(
        InsightItem(
          id: 'insight_unusual_${anomaly.id}',
          title: 'Unusual Transaction Detected',
          message: '"${anomaly.title}" (${CurrencyFormatter.format(anomaly.amount, currencyCode: currencyCode)}) in ${category.name} is significantly higher than your typical transactions in this category.',
          type: InsightType.unusual,
          metricValue: anomaly.amount,
          relatedId: anomaly.id,
        ),
      );
    }

    return insights;
  }

  /// Detects statistical anomaly / outlier transactions
  /// Compares transaction against category median and distribution
  static List<TransactionRecord> detectUnusualTransactions(List<TransactionRecord> allTransactions) {
    final expenses = allTransactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.length < 3) return [];

    // Group by category
    final categoryGroup = <String, List<TransactionRecord>>{};
    for (final tx in expenses) {
      categoryGroup.putIfAbsent(tx.categoryId, () => []).add(tx);
    }

    final outliers = <TransactionRecord>[];

    for (final group in categoryGroup.values) {
      if (group.length < 3) continue; // Need minimum samples to measure baseline

      final sortedAmounts = group.map((e) => e.amount).toList()..sort();
      final mid = sortedAmounts.length ~/ 2;
      final median = sortedAmounts.length.isOdd
          ? sortedAmounts[mid]
          : (sortedAmounts[mid - 1] + sortedAmounts[mid]) / 2.0;

      // Threshold: 2.2x median (or min 1.8x with high baseline)
      final threshold = max(median * 2.2, median + 2500.0);

      for (final tx in group) {
        if (tx.amount >= threshold && tx.amount > 3500) {
          outliers.add(tx);
        }
      }
    }

    outliers.sort((a, b) => b.amount.compareTo(a.amount));
    return outliers;
  }

  /// What-If Budget Simulator calculation model
  static WhatIfSimulationResult simulateBudget({
    required double expectedMonthlyIncome,
    required Map<String, double> hypotheticalCategoryBudgets,
    required double baseRecurringExpenses,
  }) {
    final simulatedExpenses = hypotheticalCategoryBudgets.values.fold(0.0, (sum, val) => sum + val) + baseRecurringExpenses;
    final projectedNetFlow = expectedMonthlyIncome - simulatedExpenses;
    final annualProjectedSavings = projectedNetFlow * 12;
    final savingsRatio = expectedMonthlyIncome > 0 ? (projectedNetFlow / expectedMonthlyIncome) * 100 : 0.0;

    return WhatIfSimulationResult(
      projectedMonthlyIncome: expectedMonthlyIncome,
      projectedMonthlyExpenses: simulatedExpenses,
      projectedNetSavings: projectedNetFlow,
      projectedAnnualSavings: annualProjectedSavings,
      projectedSavingsRate: savingsRatio,
    );
  }
}

class WhatIfSimulationResult {
  final double projectedMonthlyIncome;
  final double projectedMonthlyExpenses;
  final double projectedNetSavings;
  final double projectedAnnualSavings;
  final double projectedSavingsRate;

  const WhatIfSimulationResult({
    required this.projectedMonthlyIncome,
    required this.projectedMonthlyExpenses,
    required this.projectedNetSavings,
    required this.projectedAnnualSavings,
    required this.projectedSavingsRate,
  });
}
