import 'package:flutter/material.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? note;
  final int iconCode;
  final int colorValue;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.note,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
  })  : iconCode = iconCode ?? Icons.savings_outlined.codePoint,
        colorValue = colorValue ?? 0xFF0F867C,
        createdAt = createdAt ?? DateTime.now();

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  double get progressRatio {
    if (targetAmount <= 0) return 1.0;
    final ratio = currentAmount / targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Computes recommended monthly contribution needed to reach goal
  double? get recommendedMonthlyContribution {
    if (targetDate == null) return null;
    final now = DateTime.now();
    if (targetDate!.isBefore(now)) return null;

    final remaining = remainingAmount;
    if (remaining <= 0) return 0.0;

    final daysRemaining = targetDate!.difference(now).inDays;
    final monthsRemaining = (daysRemaining / 30.44).clamp(0.5, 120.0);
    return remaining / monthsRemaining;
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? note,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'note': note,
      'icon_code': iconCode,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'] as String)
          : null,
      note: map['note'] as String?,
      iconCode: map['icon_code'] as int?,
      colorValue: map['color_value'] as int?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
