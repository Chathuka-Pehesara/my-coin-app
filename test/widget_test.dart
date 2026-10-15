import 'package:flutter_test/flutter_test.dart';
import 'package:my_trans_actions/core/utils/currency_formatter.dart';
import 'package:my_trans_actions/core/services/financial_engine.dart';
import 'package:my_trans_actions/models/transaction_record.dart';
import 'package:my_trans_actions/models/category.dart';
import 'package:my_trans_actions/models/budget.dart';
import 'package:my_trans_actions/models/savings_goal.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats LKR properly by default', () {
      final formatted = CurrencyFormatter.format(15000.0, currencyCode: 'LKR');
      expect(formatted, contains('Rs.'));
      expect(formatted, contains('15,000.00'));
    });

    test('Masks balance correctly', () {
      final masked = CurrencyFormatter.format(15000.0, currencyCode: 'LKR', isMasked: true);
      expect(masked, equals('Rs. ••••••'));
    });

    test('Formats negative values with minus sign', () {
      final negativeFormatted = CurrencyFormatter.format(-2500.50, currencyCode: 'USD');
      expect(negativeFormatted, startsWith('-\$'));
      expect(negativeFormatted, contains('2,500.50'));
    });
  });

  group('FinancialEngine Tests', () {
    test('Simulates What-If budget changes accurately', () {
      final result = FinancialEngine.simulateBudget(
        expectedMonthlyIncome: 200000.0,
        hypotheticalCategoryBudgets: {
          'cat_food': 30000.0,
          'cat_rent': 50000.0,
          'cat_utilities': 20000.0,
        },
        baseRecurringExpenses: 10000.0,
      );

      // Total simulated expenses = 30k + 50k + 20k + 10k = 110k
      expect(result.projectedMonthlyExpenses, equals(110000.0));
      // Net monthly savings = 200k - 110k = 90k
      expect(result.projectedNetSavings, equals(90000.0));
      // Annual savings = 90k * 12 = 1,080,000
      expect(result.projectedAnnualSavings, equals(1080000.0));
      // Savings rate = (90k / 200k) * 100 = 45%
      expect(result.projectedSavingsRate, equals(45.0));
    });

    test('Detects unusual transaction outliers', () {
      final now = DateTime.now();
      final txList = [
        TransactionRecord(
          id: '1',
          title: 'Normal grocery 1',
          amount: 3000.0,
          type: TransactionType.expense,
          date: now,
          categoryId: 'cat_groceries',
          accountId: 'acc1',
          createdAt: now,
        ),
        TransactionRecord(
          id: '2',
          title: 'Normal grocery 2',
          amount: 3200.0,
          type: TransactionType.expense,
          date: now,
          categoryId: 'cat_groceries',
          accountId: 'acc1',
          createdAt: now,
        ),
        TransactionRecord(
          id: '3',
          title: 'Normal grocery 3',
          amount: 2800.0,
          type: TransactionType.expense,
          date: now,
          categoryId: 'cat_groceries',
          accountId: 'acc1',
          createdAt: now,
        ),
        TransactionRecord(
          id: '4',
          title: 'Enormous luxury grocery item',
          amount: 38000.0, // Significant outlier
          type: TransactionType.expense,
          date: now,
          categoryId: 'cat_groceries',
          accountId: 'acc1',
          createdAt: now,
        ),
      ];

      final outliers = FinancialEngine.detectUnusualTransactions(txList);
      expect(outliers.length, greaterThanOrEqualTo(1));
      expect(outliers.first.id, equals('4'));
    });

    test('Generates contextual insights from real transactions', () {
      final now = DateTime.now();
      final txList = [
        TransactionRecord(
          id: '1',
          title: 'Salary',
          amount: 200000.0,
          type: TransactionType.income,
          date: now,
          categoryId: 'cat_salary',
          accountId: 'acc1',
          createdAt: now,
        ),
        TransactionRecord(
          id: '2',
          title: 'Food expense',
          amount: 25000.0,
          type: TransactionType.expense,
          date: now,
          categoryId: 'cat_food',
          accountId: 'acc1',
          createdAt: now,
        ),
      ];

      final budgets = [
        Budget(
          id: 'b1',
          categoryId: null,
          limitAmount: 150000.0,
          month: now.month,
          year: now.year,
        ),
      ];

      final insights = FinancialEngine.generateInsights(
        transactions: txList,
        categories: Category.defaultCategories,
        budgets: budgets,
        currencyCode: 'LKR',
      );

      expect(insights, isNotEmpty);
    });
  });

  group('SavingsGoal Logic Tests', () {
    test('Calculates progress ratio and remaining amount correctly', () {
      final goal = SavingsGoal(
        id: 'g1',
        name: 'Emergency Fund',
        targetAmount: 100000.0,
        currentAmount: 40000.0,
      );

      expect(goal.progressRatio, equals(0.4));
      expect(goal.remainingAmount, equals(60000.0));
    });
  });
}
