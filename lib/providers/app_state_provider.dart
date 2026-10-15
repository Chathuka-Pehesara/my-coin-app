import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';
import '../models/insight_item.dart';
import '../core/services/database_service.dart';
import '../core/services/preferences_service.dart';
import '../core/services/financial_engine.dart';
import '../core/services/shake_detector_service.dart';

enum TransactionSortOption {
  newest,
  oldest,
  highestAmount,
  lowestAmount;

  String get displayName {
    switch (this) {
      case TransactionSortOption.newest:
        return 'Newest First';
      case TransactionSortOption.oldest:
        return 'Oldest First';
      case TransactionSortOption.highestAmount:
        return 'Highest Amount';
      case TransactionSortOption.lowestAmount:
        return 'Lowest Amount';
    }
  }
}

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PreferencesService _prefs;

  bool _isLoading = true;
  String _currencyCode = 'LKR';
  bool _isBalanceMasked = false;
  bool _isShakeToHideEnabled = true;

  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<TransactionRecord> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  List<RecurringTransaction> _recurringTransactions = [];
  List<InsightItem> _insights = [];

  // Filter & Search states
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategoryId;
  String? _filterAccountId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  TransactionSortOption _sortOption = TransactionSortOption.newest;

  AppStateProvider(this._prefs) {
    _currencyCode = _prefs.currencyCode;
    _isBalanceMasked = _prefs.isBalanceMasked;
    _isShakeToHideEnabled = _prefs.isShakeToHideEnabled;
    _initShakeDetection();
    loadAllData();
  }

  // Getters
  bool get isLoading => _isLoading;
  String get currencyCode => _currencyCode;
  bool get isBalanceMasked => _isBalanceMasked;
  bool get isShakeToHideEnabled => _isShakeToHideEnabled;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  List<RecurringTransaction> get recurringTransactions => List.unmodifiable(_recurringTransactions);
  List<InsightItem> get insights => List.unmodifiable(_insights);

  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;
  String? get filterAccountId => _filterAccountId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  TransactionSortOption get sortOption => _sortOption;

  // Filtered transactions
  List<TransactionRecord> get filteredTransactions {
    return _transactions.where((t) {
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchMerchant = (t.merchant ?? '').toLowerCase().contains(query);
        final matchNote = (t.note ?? '').toLowerCase().contains(query);
        if (!matchTitle && !matchMerchant && !matchNote) return false;
      }

      // Type filter
      if (_filterType != null && t.type != _filterType) return false;

      // Category filter
      if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;

      // Account filter
      if (_filterAccountId != null &&
          t.accountId != _filterAccountId &&
          t.toAccountId != _filterAccountId) {
        return false;
      }

      // Date range filter
      if (_filterStartDate != null && t.date.isBefore(_filterStartDate!)) return false;
      if (_filterEndDate != null && t.date.isAfter(_filterEndDate!)) return false;

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_sortOption) {
          case TransactionSortOption.newest:
            return b.date.compareTo(a.date);
          case TransactionSortOption.oldest:
            return a.date.compareTo(b.date);
          case TransactionSortOption.highestAmount:
            return b.amount.compareTo(a.amount);
          case TransactionSortOption.lowestAmount:
            return a.amount.compareTo(b.amount);
        }
      });
  }

  // ================= FINANCIAL METRICS =================
  /// Total net balance across included accounts
  double get totalNetBalance {
    return _accounts
        .where((a) => a.isIncludedInTotal)
        .fold(0.0, (sum, a) => sum + a.balance);
  }

  /// Current month income
  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Current month expenses
  double get currentMonthExpenses {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Current month net cash flow
  double get currentMonthNetSavings => currentMonthIncome - currentMonthExpenses;

  /// Overall budget for current month
  Budget? get currentOverallBudget {
    final now = DateTime.now();
    try {
      return _budgets.firstWhere((b) => b.isOverall && b.month == now.month && b.year == now.year);
    } catch (_) {
      return null;
    }
  }

  /// Remaining overall monthly budget
  double get remainingOverallBudget {
    final budget = currentOverallBudget;
    if (budget == null) return 0.0;
    return budget.limitAmount - currentMonthExpenses;
  }

  /// Category spend breakdown for current month (sorted descending)
  Map<String, double> get categoryExpenseBreakdown {
    final now = DateTime.now();
    final map = <String, double>{};
    final monthlyExpenses = _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month);

    for (final tx in monthlyExpenses) {
      map[tx.categoryId] = (map[tx.categoryId] ?? 0.0) + tx.amount;
    }
    return map;
  }

  // ================= DATA LOADING =================
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _db.getAccounts();
      _categories = await _db.getCategories();
      _transactions = await _db.getTransactions();
      _budgets = await _db.getBudgets();
      _savingsGoals = await _db.getSavingsGoals();
      _recurringTransactions = await _db.getRecurringTransactions();

      _recomputeInsights();
    } catch (e) {
      debugPrint('Error loading data in AppStateProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recomputeInsights() {
    _insights = FinancialEngine.generateInsights(
      transactions: _transactions,
      categories: _categories,
      budgets: _budgets,
      currencyCode: _currencyCode,
    );
  }

  // ================= PREFERENCES =================
  void _initShakeDetection() {
    if (_isShakeToHideEnabled) {
      ShakeDetectorService.instance.startListening(
        onShake: () {
          triggerShakePrivacyToggle();
        },
      );
    } else {
      ShakeDetectorService.instance.stopListening();
    }
  }

  Future<void> setShakeToHideEnabled(bool enabled) async {
    _isShakeToHideEnabled = enabled;
    await _prefs.setShakeToHideEnabled(enabled);
    _initShakeDetection();
    notifyListeners();
  }

  Future<void> triggerShakePrivacyToggle() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    await toggleBalanceMasking();
  }

  Future<void> toggleBalanceMasking() async {
    _isBalanceMasked = !_isBalanceMasked;
    await _prefs.setBalanceMasked(_isBalanceMasked);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    await _prefs.setCurrencyCode(code);
    _recomputeInsights();
    notifyListeners();
  }

  // ================= TRANSACTION CRUD =================
  Future<void> addTransaction(TransactionRecord tx) async {
    await _db.addTransaction(tx);
    await loadAllData();
  }

  Future<void> updateTransaction(TransactionRecord updated, TransactionRecord original) async {
    await _db.updateTransaction(updated, original);
    await loadAllData();
  }

  Future<void> deleteTransaction(TransactionRecord tx) async {
    await _db.deleteTransaction(tx);
    await loadAllData();
  }

  Future<void> duplicateTransaction(TransactionRecord tx) async {
    final duplicate = tx.copyWith(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await addTransaction(duplicate);
  }

  // ================= FILTERS =================
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setFilterAccount(String? accountId) {
    _filterAccountId = accountId;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void setSortOption(TransactionSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterCategoryId = null;
    _filterAccountId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _sortOption = TransactionSortOption.newest;
    notifyListeners();
  }

  // ================= ACCOUNTS =================
  Future<void> saveAccount(Account account) async {
    await _db.saveAccount(account);
    await loadAllData();
  }

  Future<void> deleteAccount(String accountId) async {
    await _db.deleteAccount(accountId);
    await loadAllData();
  }

  // ================= CATEGORIES =================
  Future<void> saveCategory(Category category) async {
    await _db.saveCategory(category);
    await loadAllData();
  }

  Future<bool> deleteCategory(String categoryId) async {
    // Check if category is used in transactions
    final isUsed = _transactions.any((t) => t.categoryId == categoryId);
    if (isUsed) {
      return false; // Prevent silent data corruption
    }
    await _db.deleteCategory(categoryId);
    await loadAllData();
    return true;
  }

  // ================= BUDGETS =================
  Future<void> saveBudget(Budget budget) async {
    await _db.saveBudget(budget);
    await loadAllData();
  }

  Future<void> deleteBudget(String budgetId) async {
    await _db.deleteBudget(budgetId);
    await loadAllData();
  }

  // ================= SAVINGS GOALS =================
  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    await _db.saveSavingsGoal(goal);
    await loadAllData();
  }

  Future<void> depositToGoal({
    required SavingsGoal goal,
    required double amount,
    required String fromAccountId,
  }) async {
    final updatedGoal = goal.copyWith(currentAmount: goal.currentAmount + amount);
    await _db.saveSavingsGoal(updatedGoal);

    // Create linked record to adjust source account balance
    final tx = TransactionRecord(
      id: 'tx_goal_dep_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Contribution: ${goal.name}',
      amount: amount,
      type: TransactionType.expense,
      date: DateTime.now(),
      categoryId: 'cat_investment',
      accountId: fromAccountId,
      note: 'Savings goal deposit toward "${goal.name}"',
      createdAt: DateTime.now(),
    );
    await _db.addTransaction(tx);
    await loadAllData();
  }

  Future<void> withdrawFromGoal({
    required SavingsGoal goal,
    required double amount,
    required String toAccountId,
  }) async {
    final updatedAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);
    final updatedGoal = goal.copyWith(currentAmount: updatedAmount);
    await _db.saveSavingsGoal(updatedGoal);

    // Create linked income transaction
    final tx = TransactionRecord(
      id: 'tx_goal_wdr_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Withdrawal: ${goal.name}',
      amount: amount,
      type: TransactionType.income,
      date: DateTime.now(),
      categoryId: 'cat_investment',
      accountId: toAccountId,
      note: 'Savings goal withdrawal from "${goal.name}"',
      createdAt: DateTime.now(),
    );
    await _db.addTransaction(tx);
    await loadAllData();
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await _db.deleteSavingsGoal(goalId);
    await loadAllData();
  }

  // ================= RECURRING TRANSACTIONS =================
  Future<void> saveRecurringTransaction(RecurringTransaction recurring) async {
    await _db.saveRecurringTransaction(recurring);
    await loadAllData();
  }

  Future<void> toggleRecurringActive(RecurringTransaction recurring) async {
    final updated = recurring.copyWith(isActive: !recurring.isActive);
    await _db.saveRecurringTransaction(updated);
    await loadAllData();
  }

  Future<void> executeRecurringNow(RecurringTransaction recurring) async {
    final now = DateTime.now();
    final newTx = TransactionRecord(
      id: 'tx_rec_${DateTime.now().millisecondsSinceEpoch}',
      title: recurring.title,
      amount: recurring.amount,
      type: recurring.type,
      date: now,
      categoryId: recurring.categoryId,
      accountId: recurring.accountId,
      toAccountId: recurring.toAccountId,
      isRecurring: true,
      recurringId: recurring.id,
      note: recurring.note ?? 'Generated from recurring schedule',
      createdAt: now,
    );

    final nextOccurrence = recurring.frequency.calculateNextDate(recurring.nextDate);
    final updatedRecurring = recurring.copyWith(
      nextDate: nextOccurrence,
      lastGeneratedDate: now,
    );

    await _db.addTransaction(newTx);
    await _db.saveRecurringTransaction(updatedRecurring);
    await loadAllData();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _db.deleteRecurringTransaction(id);
    await loadAllData();
  }

  // ================= RESET =================
  Future<void> resetAllData() async {
    await _db.resetDatabase();
    await loadAllData();
  }
}
