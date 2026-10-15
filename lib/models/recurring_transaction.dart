import 'transaction_record.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  DateTime calculateNextDate(DateTime fromDate) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        final nextMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
        final nextYear = fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
        final day = fromDate.day > 28 ? 28 : fromDate.day;
        return DateTime(nextYear, nextMonth, day, fromDate.hour, fromDate.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day, fromDate.hour, fromDate.minute);
    }
  }
}

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime nextDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final String? note;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.frequency,
    required this.startDate,
    required this.nextDate,
    this.lastGeneratedDate,
    this.isActive = true,
    this.note,
  });

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDate,
    DateTime? lastGeneratedDate,
    bool? isActive,
    String? note,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDate: nextDate ?? this.nextDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String(),
      'next_date': nextDate.toIso8601String(),
      'last_generated_date': lastGeneratedDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'note': note,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      nextDate: DateTime.parse(map['next_date'] as String),
      lastGeneratedDate: map['last_generated_date'] != null
          ? DateTime.tryParse(map['last_generated_date'] as String)
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      note: map['note'] as String?,
    );
  }
}
