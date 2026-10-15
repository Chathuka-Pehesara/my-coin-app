import 'package:flutter/material.dart';

enum AccountType {
  cash,
  bank,
  savings,
  creditCard,
  custom;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.custom:
        return 'Custom Account';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case AccountType.cash:
        return Icons.account_balance_wallet_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.custom:
        return Icons.wallet_outlined;
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final int iconCode;
  final int colorValue;
  final bool isIncludedInTotal;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'LKR',
    int? iconCode,
    int? colorValue,
    this.isIncludedInTotal = true,
    DateTime? createdAt,
  })  : iconCode = iconCode ?? type.defaultIcon.codePoint,
        colorValue = colorValue ?? 0xFFC5A059,
        createdAt = createdAt ?? DateTime.now();

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    int? iconCode,
    int? colorValue,
    bool? isIncludedInTotal,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isIncludedInTotal: isIncludedInTotal ?? this.isIncludedInTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'icon_code': iconCode,
      'color_value': colorValue,
      'is_included_in_total': isIncludedInTotal ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.custom,
      ),
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'LKR',
      iconCode: map['icon_code'] as int?,
      colorValue: map['color_value'] as int?,
      isIncludedInTotal: (map['is_included_in_total'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
