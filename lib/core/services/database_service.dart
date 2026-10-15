import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction_record.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../../models/recurring_transaction.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  bool _useInMemoryFallback = false;

  // In-memory fallback stores
  final List<Account> _memAccounts = [];
  final List<Category> _memCategories = [];
  final List<TransactionRecord> _memTransactions = [];
  final List<Budget> _memBudgets = [];
  final List<SavingsGoal> _memGoals = [];
  final List<RecurringTransaction> _memRecurring = [];

  Future<Database?> get database async {
    if (_useInMemoryFallback) return null;
    if (_database != null) return _database;

    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      debugPrint('SQLite initialization error, falling back to in-memory store: $e');
      _useInMemoryFallback = true;
      _seedInMemoryIfEmpty();
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'my_trans_actions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_included_in_total INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL,
        monthly_budget REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        merchant TEXT,
        note TEXT,
        is_recurring INTEGER NOT NULL,
        recurring_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        limit_amount REAL NOT NULL,
        period TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        target_date TEXT,
        note TEXT,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        frequency TEXT NOT NULL,
        start_date TEXT NOT NULL,
        next_date TEXT NOT NULL,
        last_generated_date TEXT,
        is_active INTEGER NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Seed Clean Starter Accounts
    final initialAccounts = [
      Account(
        id: 'acc_cash_wallet',
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 0.0,
        currency: 'LKR',
        iconCode: 0xe041,
        colorValue: 0xFF2D8A4E,
      ),
      Account(
        id: 'acc_primary_bank',
        name: 'Bank Account',
        type: AccountType.bank,
        balance: 0.0,
        currency: 'LKR',
        iconCode: 0xe040,
        colorValue: 0xFFC5A059,
      ),
    ];

    for (final acc in initialAccounts) {
      await db.insert('accounts', acc.toMap());
    }

    // 2. Seed Standard Categories
    for (final cat in Category.defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  void _seedInMemoryIfEmpty() {
    if (_memAccounts.isNotEmpty || _memCategories.isNotEmpty) return;

    _memAccounts.addAll([
      Account(
        id: 'acc_cash_wallet',
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 0.0,
        currency: 'LKR',
        iconCode: 0xe041,
        colorValue: 0xFF2D8A4E,
      ),
      Account(
        id: 'acc_primary_bank',
        name: 'Bank Account',
        type: AccountType.bank,
        balance: 0.0,
        currency: 'LKR',
        iconCode: 0xe040,
        colorValue: 0xFFC5A059,
      ),
    ]);

    _memCategories.addAll(Category.defaultCategories);
  }

  // ================= ACCOUNTS =================
  Future<List<Account>> getAccounts() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('accounts', orderBy: 'created_at ASC');
      return maps.map((e) => Account.fromMap(e)).toList();
    }
    return List.from(_memAccounts);
  }

  Future<void> saveAccount(Account account) async {
    final db = await database;
    if (db != null) {
      await db.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final index = _memAccounts.indexWhere((a) => a.id == account.id);
      if (index >= 0) {
        _memAccounts[index] = account;
      } else {
        _memAccounts.add(account);
      }
    }
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    } else {
      _memAccounts.removeWhere((a) => a.id == id);
    }
  }

  // ================= CATEGORIES =================
  Future<List<Category>> getCategories() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('categories', orderBy: 'name ASC');
      return maps.map((e) => Category.fromMap(e)).toList();
    }
    return List.from(_memCategories);
  }

  Future<void> saveCategory(Category category) async {
    final db = await database;
    if (db != null) {
      await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final index = _memCategories.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        _memCategories[index] = category;
      } else {
        _memCategories.add(category);
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    } else {
      _memCategories.removeWhere((c) => c.id == id);
    }
  }

  // ================= TRANSACTIONS =================
  Future<List<TransactionRecord>> getTransactions() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('transactions', orderBy: 'date DESC, created_at DESC');
      return maps.map((e) => TransactionRecord.fromMap(e)).toList();
    }
    final list = List<TransactionRecord>.from(_memTransactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addTransaction(TransactionRecord tx) async {
    final db = await database;
    if (db != null) {
      await db.insert('transactions', tx.toMap());
    } else {
      _memTransactions.add(tx);
    }
    await _adjustAccountBalancesForTransaction(tx, isAddition: true);
  }

  Future<void> updateTransaction(TransactionRecord updated, TransactionRecord original) async {
    // Revert original impact
    await _adjustAccountBalancesForTransaction(original, isAddition: false);

    final db = await database;
    if (db != null) {
      await db.update('transactions', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
    } else {
      final index = _memTransactions.indexWhere((t) => t.id == updated.id);
      if (index >= 0) {
        _memTransactions[index] = updated;
      }
    }
    // Apply updated impact
    await _adjustAccountBalancesForTransaction(updated, isAddition: true);
  }

  Future<void> deleteTransaction(TransactionRecord tx) async {
    final db = await database;
    if (db != null) {
      await db.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);
    } else {
      _memTransactions.removeWhere((t) => t.id == tx.id);
    }
    // Revert balance change
    await _adjustAccountBalancesForTransaction(tx, isAddition: false);
  }

  Future<void> _adjustAccountBalancesForTransaction(TransactionRecord tx, {required bool isAddition}) async {
    final accounts = await getAccounts();
    final sourceAccount = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => accounts.first);
    final multiplier = isAddition ? 1.0 : -1.0;

    if (tx.type == TransactionType.income) {
      final newBalance = sourceAccount.balance + (tx.amount * multiplier);
      await saveAccount(sourceAccount.copyWith(balance: newBalance));
    } else if (tx.type == TransactionType.expense) {
      final newBalance = sourceAccount.balance - (tx.amount * multiplier);
      await saveAccount(sourceAccount.copyWith(balance: newBalance));
    } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
      final newSrcBalance = sourceAccount.balance - (tx.amount * multiplier);
      await saveAccount(sourceAccount.copyWith(balance: newSrcBalance));

      final destAccount = accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => accounts.first);
      final newDstBalance = destAccount.balance + (tx.amount * multiplier);
      await saveAccount(destAccount.copyWith(balance: newDstBalance));
    }
  }

  // ================= BUDGETS =================
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('budgets');
      return maps.map((e) => Budget.fromMap(e)).toList();
    }
    return List.from(_memBudgets);
  }

  Future<void> saveBudget(Budget budget) async {
    final db = await database;
    if (db != null) {
      await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final index = _memBudgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _memBudgets[index] = budget;
      } else {
        _memBudgets.add(budget);
      }
    }
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    } else {
      _memBudgets.removeWhere((b) => b.id == id);
    }
  }

  // ================= SAVINGS GOALS =================
  Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('savings_goals');
      return maps.map((e) => SavingsGoal.fromMap(e)).toList();
    }
    return List.from(_memGoals);
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    if (db != null) {
      await db.insert('savings_goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final index = _memGoals.indexWhere((g) => g.id == goal.id);
      if (index >= 0) {
        _memGoals[index] = goal;
      } else {
        _memGoals.add(goal);
      }
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    } else {
      _memGoals.removeWhere((g) => g.id == id);
    }
  }

  // ================= RECURRING TRANSACTIONS =================
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('recurring_transactions');
      return maps.map((e) => RecurringTransaction.fromMap(e)).toList();
    }
    return List.from(_memRecurring);
  }

  Future<void> saveRecurringTransaction(RecurringTransaction recurring) async {
    final db = await database;
    if (db != null) {
      await db.insert('recurring_transactions', recurring.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final index = _memRecurring.indexWhere((r) => r.id == recurring.id);
      if (index >= 0) {
        _memRecurring[index] = recurring;
      } else {
        _memRecurring.add(recurring);
      }
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
    } else {
      _memRecurring.removeWhere((r) => r.id == id);
    }
  }

  /// Clears all database tables and re-seeds defaults
  Future<void> resetDatabase() async {
    final db = await database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('savings_goals');
      await db.delete('recurring_transactions');
      await db.delete('categories');
      await db.delete('accounts');
      await _seedInitialData(db);
    } else {
      _memAccounts.clear();
      _memCategories.clear();
      _memTransactions.clear();
      _memBudgets.clear();
      _memGoals.clear();
      _memRecurring.clear();
      _seedInMemoryIfEmpty();
    }
  }
}
