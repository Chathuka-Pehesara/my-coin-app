enum BudgetPeriod {
  monthly,
  yearly;

  String get displayName => this == BudgetPeriod.monthly ? 'Monthly' : 'Yearly';
}

enum BudgetStatus {
  healthy,
  warning,
  exceeded;

  String get label {
    switch (this) {
      case BudgetStatus.healthy:
        return 'On Track';
      case BudgetStatus.warning:
        return 'Near Limit';
      case BudgetStatus.exceeded:
        return 'Exceeded';
    }
  }
}

class Budget {
  final String id;
  final String? categoryId; // null means overall global budget
  final double limitAmount;
  final BudgetPeriod period;
  final int month;
  final int year;

  const Budget({
    required this.id,
    this.categoryId,
    required this.limitAmount,
    this.period = BudgetPeriod.monthly,
    required this.month,
    required this.year,
  });

  bool get isOverall => categoryId == null || categoryId!.isEmpty;

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limitAmount,
    BudgetPeriod period = BudgetPeriod.monthly,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'period': period.name,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}
