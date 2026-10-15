import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return AppColors.incomeGreen;
      case TransactionType.expense:
        return AppColors.expenseCoral;
      case TransactionType.transfer:
        return AppColors.transferBlue;
    }
  }

  Color get lightColor {
    switch (this) {
      case TransactionType.income:
        return AppColors.incomeGreenLight;
      case TransactionType.expense:
        return AppColors.expenseCoralLight;
      case TransactionType.transfer:
        return AppColors.transferBlueLight;
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }
}

class TransactionRecord {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String categoryId;
  final String accountId; // Source account (or only account for income/expense)
  final String? toAccountId; // Destination account for transfers
  final String? merchant;
  final String? note;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;

  const TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.merchant,
    this.note,
    this.isRecurring = false,
    this.recurringId,
    required this.createdAt,
  });

  TransactionRecord copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? merchant,
    String? note,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'merchant': merchant,
      'note': note,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_id': recurringId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      merchant: map['merchant'] as String?,
      note: map['note'] as String?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurringId: map['recurring_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
