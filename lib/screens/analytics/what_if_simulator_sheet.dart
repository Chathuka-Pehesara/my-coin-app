import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/financial_engine.dart';
import '../../providers/app_state_provider.dart';

class WhatIfSimulatorSheet extends StatefulWidget {
  const WhatIfSimulatorSheet({super.key});

  @override
  State<WhatIfSimulatorSheet> createState() => _WhatIfSimulatorSheetState();
}

class _WhatIfSimulatorSheetState extends State<WhatIfSimulatorSheet> {
  late double _hypotheticalIncome;
  final Map<String, double> _categoryBudgets = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _hypotheticalIncome = state.currentMonthIncome > 0 ? state.currentMonthIncome : 250000.0;

    // Initialize category budgets from actual breakdown
    final breakdown = state.categoryExpenseBreakdown;
    for (final cat in state.categories.where((c) => c.type.name == 'expense')) {
      final actualSpend = breakdown[cat.id] ?? 15000.0;
      _categoryBudgets[cat.id] = actualSpend > 0 ? actualSpend : 10000.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    // Calculate simulation result
    final simulation = FinancialEngine.simulateBudget(
      expectedMonthlyIncome: _hypotheticalIncome,
      hypotheticalCategoryBudgets: _categoryBudgets,
      baseRecurringExpenses: 0.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.goldSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: AppColors.goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'What-If Budget Simulator',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulate how modifying your income or trimming specific expense categories alters your monthly surplus and long-term annual savings.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Simulation Result Live KPI Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.goldSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.goldBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROJECTED MONTHLY SAVINGS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(
                                    simulation.projectedNetSavings,
                                    currencyCode: state.currencyCode,
                                  ),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: simulation.projectedNetSavings >= 0
                                        ? AppColors.incomeGreen
                                        : AppColors.expenseCoral,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (simulation.projectedNetSavings >= 0
                                        ? AppColors.incomeGreen
                                        : AppColors.expenseCoral)
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${simulation.projectedSavingsRate.toStringAsFixed(1)}% savings rate',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: simulation.projectedNetSavings >= 0
                                      ? AppColors.incomeGreen
                                      : AppColors.expenseCoral,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.goldBorder,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Projected 1-Year Wealth Growth:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                simulation.projectedAnnualSavings,
                                currencyCode: state.currencyCode,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: simulation.projectedAnnualSavings >= 0
                                    ? AppColors.incomeGreen
                                    : AppColors.expenseCoral,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Income Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expected Monthly Income',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormatter.format(_hypotheticalIncome, currencyCode: state.currencyCode, decimalDigits: 0),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.goldDark),
                      ),
                    ],
                  ),
                  Slider(
                    value: _hypotheticalIncome.clamp(50000.0, 1000000.0),
                    min: 50000.0,
                    max: 1000000.0,
                    divisions: 95,
                    activeColor: AppColors.goldPrimary,
                    onChanged: (val) => setState(() => _hypotheticalIncome = val),
                  ),
                  const SizedBox(height: 20),

                  // Category sliders
                  const Text(
                    'Simulated Category Expense Budgets',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...state.categories.where((c) => c.type.name == 'expense').map((cat) {
                    final budgetVal = _categoryBudgets[cat.id] ?? 20000.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(cat.icon, size: 16, color: cat.color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(budgetVal, currencyCode: state.currencyCode, decimalDigits: 0),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Slider(
                            value: budgetVal.clamp(0.0, 150000.0),
                            min: 0.0,
                            max: 150000.0,
                            divisions: 150,
                            activeColor: cat.color,
                            onChanged: (val) {
                              setState(() => _categoryBudgets[cat.id] = val);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
