import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_record.dart';
import '../providers/app_state_provider.dart';

class SpendingHeatmapCard extends StatelessWidget {
  const SpendingHeatmapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Map each day of current month (1..daysInMonth) to its expense transactions
    final Map<int, List<TransactionRecord>> dailyTransactions = {};
    for (int day = 1; day <= daysInMonth; day++) {
      dailyTransactions[day] = [];
    }

    double totalMonthExpense = 0.0;
    for (final tx in state.transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        dailyTransactions[tx.date.day]?.add(tx);
        totalMonthExpense += tx.amount;
      }
    }

    final double avgDailySpend = now.day > 0 ? (totalMonthExpense / now.day) : 0.0;

    // Calculate zero-spend days and current streak
    int zeroSpendCount = 0;
    int currentStreak = 0;
    bool streakActive = true;

    for (int day = now.day; day >= 1; day--) {
      final txs = dailyTransactions[day] ?? [];
      final spent = txs.fold(0.0, (sum, t) => sum + t.amount);
      if (spent == 0.0) {
        if (streakActive) currentStreak++;
      } else {
        streakActive = false;
      }
    }

    for (int day = 1; day <= now.day; day++) {
      final txs = dailyTransactions[day] ?? [];
      final spent = txs.fold(0.0, (sum, t) => sum + t.amount);
      if (spent == 0.0) {
        zeroSpendCount++;
      }
    }

    final isZeroSpendHero = zeroSpendCount >= 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.goldDark),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Rhythm (${DateFormat.MMMM().format(now)})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: isDark ? 0.2 : 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 11)),
                      Text(
                        '$currentStreak day streak',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Discipline Metrics Row
          Row(
            children: [
              _buildMetricPill(
                isDark: isDark,
                icon: Icons.eco_rounded,
                iconColor: AppColors.incomeGreen,
                label: 'Zero-Spend Days',
                value: '$zeroSpendCount / ${now.day} days',
              ),
              const SizedBox(width: 8),
              if (isZeroSpendHero)
                _buildMetricPill(
                  isDark: isDark,
                  icon: Icons.military_tech_rounded,
                  iconColor: AppColors.goldDark,
                  label: 'Discipline Status',
                  value: 'Zero-Spend Hero 🛡️',
                )
              else
                _buildMetricPill(
                  isDark: isDark,
                  icon: Icons.trending_down_rounded,
                  iconColor: AppColors.savingsTeal,
                  label: 'Daily Average',
                  value: CurrencyFormatter.format(
                    avgDailySpend,
                    currencyCode: state.currencyCode,
                    isMasked: state.isBalanceMasked,
                    decimalDigits: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Labels Row
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildMonthGrid(
            context: context,
            now: now,
            firstDayOfMonth: firstDayOfMonth,
            daysInMonth: daysInMonth,
            dailyTransactions: dailyTransactions,
            avgDailySpend: avgDailySpend,
            isDark: isDark,
            currencyCode: state.currencyCode,
            isMasked: state.isBalanceMasked,
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Zero',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              _buildLegendBox(_getColorForSpend(0, avgDailySpend, isDark, false)),
              const SizedBox(width: 3),
              _buildLegendBox(_getColorForSpend(avgDailySpend * 0.3, avgDailySpend, isDark, false)),
              const SizedBox(width: 3),
              _buildLegendBox(_getColorForSpend(avgDailySpend * 0.75, avgDailySpend, isDark, false)),
              const SizedBox(width: 3),
              _buildLegendBox(_getColorForSpend(avgDailySpend * 1.2, avgDailySpend, isDark, false)),
              const SizedBox(width: 3),
              _buildLegendBox(_getColorForSpend(avgDailySpend * 2.0, avgDailySpend, isDark, false)),
              const SizedBox(width: 4),
              Text(
                'High Spend',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid({
    required BuildContext context,
    required DateTime now,
    required DateTime firstDayOfMonth,
    required int daysInMonth,
    required Map<int, List<TransactionRecord>> dailyTransactions,
    required double avgDailySpend,
    required bool isDark,
    required String currencyCode,
    required bool isMasked,
  }) {
    // Weekday is 1 (Monday) to 7 (Sunday)
    final int leadingEmptyDays = firstDayOfMonth.weekday - 1;
    final int totalCells = leadingEmptyDays + daysInMonth;
    final int totalWeeks = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalWeeks, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(7, (dayOfWeekIndex) {
              final cellIndex = (weekIndex * 7) + dayOfWeekIndex;
              final dayNumber = cellIndex - leadingEmptyDays + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 32));
              }

              final isFutureDay = dayNumber > now.day;
              final isToday = dayNumber == now.day;
              final txs = dailyTransactions[dayNumber] ?? [];
              final daySpend = txs.fold(0.0, (sum, t) => sum + t.amount);

              final cellColor = isFutureDay
                  ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))
                  : _getColorForSpend(daySpend, avgDailySpend, isDark, isFutureDay);

              return Expanded(
                child: GestureDetector(
                  onTap: isFutureDay
                      ? null
                      : () => _showDayDetailSheet(
                            context: context,
                            date: DateTime(now.year, now.month, dayNumber),
                            spent: daySpend,
                            transactions: txs,
                            isDark: isDark,
                            currencyCode: currencyCode,
                            isMasked: isMasked,
                          ),
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: AppColors.goldPrimary, width: 1.8)
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 0.8,
                            ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isFutureDay
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (daySpend == 0
                                  ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                                  : Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _getColorForSpend(double spend, double avg, bool isDark, bool isFuture) {
    if (isFuture) {
      return isDark ? Colors.white10 : Colors.black12;
    }
    if (spend <= 0.0) {
      return isDark ? const Color(0xFF1E252B) : const Color(0xFFE9EEF3);
    }
    if (avg <= 0) {
      return AppColors.goldPrimary;
    }

    final ratio = spend / avg;
    if (ratio < 0.35) {
      return const Color(0xFFD4AF37).withValues(alpha: 0.65);
    } else if (ratio < 0.85) {
      return const Color(0xFFC59B27);
    } else if (ratio < 1.5) {
      return const Color(0xFF9E7818);
    } else {
      return AppColors.expenseCoral;
    }
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showDayDetailSheet({
    required BuildContext context,
    required DateTime date,
    required double spent,
    required List<TransactionRecord> transactions,
    required bool isDark,
    required String currencyCode,
    required bool isMasked,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: spent == 0 ? AppColors.incomeGreenLight : AppColors.expenseCoralLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      spent == 0
                          ? 'Zero Spend 🎉'
                          : CurrencyFormatter.format(spent, currencyCode: currencyCode, isMasked: isMasked),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: spent == 0 ? AppColors.incomeGreen : AppColors.expenseCoral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.incomeGreen, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No expenses recorded on this day. Great job preserving your capital!',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Recorded Expenses:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (_, index) {
                      final tx = transactions[index];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.expenseCoralLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.expenseCoral),
                          ),
                          const SizedBox(width: 10),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '-${CurrencyFormatter.format(tx.amount, currencyCode: currencyCode, isMasked: isMasked)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expenseCoral,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
