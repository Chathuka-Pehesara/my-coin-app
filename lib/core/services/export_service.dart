import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_record.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../../models/recurring_transaction.dart';
import 'database_service.dart';

class ExportService {
  /// Converts a matrix of cells into an RFC 4180 compliant CSV string
  static String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((field) {
        final str = (field ?? '').toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
  }

  /// Generates a structured CSV file from transactions and triggers system share sheet
  static Future<String> exportTransactionsToCsv({
    required List<TransactionRecord> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final accountMap = {for (var a in accounts) a.id: a.name};
    final categoryMap = {for (var c in categories) c.id: c.name};

    final rows = <List<dynamic>>[];
    // Header
    rows.add([
      'Transaction ID',
      'Date',
      'Time',
      'Title',
      'Type',
      'Category',
      'Account / Source',
      'Destination Account',
      'Amount',
      'Merchant',
      'Note',
    ]);

    for (final tx in transactions) {
      rows.add([
        tx.id,
        DateFormat('yyyy-MM-dd').format(tx.date),
        DateFormat('HH:mm:ss').format(tx.date),
        tx.title,
        tx.type.name.toUpperCase(),
        categoryMap[tx.categoryId] ?? 'Unknown',
        accountMap[tx.accountId] ?? 'Unknown',
        tx.toAccountId != null ? (accountMap[tx.toAccountId] ?? 'Unknown') : '',
        tx.amount,
        tx.merchant ?? '',
        tx.note ?? '',
      ]);
    }

    final csvContent = _convertToCsv(rows);

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/my_trans_actions_$timestamp.csv');
    await file.writeAsString(csvContent);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Trans Actions - Financial Records CSV ($timestamp)',
        ),
      );
    } catch (_) {
      // Fallback
    }

    return file.path;
  }

  /// Generates full JSON backup of the user database
  static Future<String> createJsonBackup({
    required List<Account> accounts,
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> goals,
    required List<RecurringTransaction> recurring,
  }) async {
    final backupData = {
      'app': 'My Trans Actions',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'budgets': budgets.map((b) => b.toMap()).toList(),
      'savings_goals': goals.map((g) => g.toMap()).toList(),
      'recurring_transactions': recurring.map((r) => r.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/my_trans_actions_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Trans Actions - Complete Backup ($timestamp)',
        ),
      );
    } catch (_) {
      // Fallback
    }

    return file.path;
  }

  /// Restores complete database from a JSON backup string
  static Future<bool> restoreFromJsonString(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (decoded['app'] != 'My Trans Actions') {
        return false;
      }

      final db = DatabaseService.instance;
      // Clear current data
      await db.resetDatabase();

      // Restore accounts
      if (decoded['accounts'] is List) {
        for (final m in (decoded['accounts'] as List)) {
          await db.saveAccount(Account.fromMap(m as Map<String, dynamic>));
        }
      }

      // Restore categories
      if (decoded['categories'] is List) {
        for (final m in (decoded['categories'] as List)) {
          await db.saveCategory(Category.fromMap(m as Map<String, dynamic>));
        }
      }

      // Restore transactions
      if (decoded['transactions'] is List) {
        for (final m in (decoded['transactions'] as List)) {
          await db.addTransaction(TransactionRecord.fromMap(m as Map<String, dynamic>));
        }
      }

      // Restore budgets
      if (decoded['budgets'] is List) {
        for (final m in (decoded['budgets'] as List)) {
          await db.saveBudget(Budget.fromMap(m as Map<String, dynamic>));
        }
      }

      // Restore goals
      if (decoded['savings_goals'] is List) {
        for (final m in (decoded['savings_goals'] as List)) {
          await db.saveSavingsGoal(SavingsGoal.fromMap(m as Map<String, dynamic>));
        }
      }

      // Restore recurring
      if (decoded['recurring_transactions'] is List) {
        for (final m in (decoded['recurring_transactions'] as List)) {
          await db.saveRecurringTransaction(RecurringTransaction.fromMap(m as Map<String, dynamic>));
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
