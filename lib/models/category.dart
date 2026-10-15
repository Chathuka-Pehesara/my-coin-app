import 'package:flutter/material.dart';
import '../core/utils/icon_helper.dart';

enum CategoryType {
  income,
  expense;

  String get displayName => this == CategoryType.income ? 'Income' : 'Expense';
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final int iconCode;
  final int colorValue;
  final bool isDefault;
  final double? monthlyBudget;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
    this.isDefault = false,
    this.monthlyBudget,
  });

  IconData get icon => IconHelper.getIcon(iconCode, Icons.category_outlined);
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    int? iconCode,
    int? colorValue,
    bool? isDefault,
    double? monthlyBudget,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'monthly_budget': monthlyBudget,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble(),
    );
  }

  static List<Category> get defaultCategories => [
    // Income
    const Category(
      id: 'cat_salary',
      name: 'Salary',
      type: CategoryType.income,
      iconCode: 0xe040, // attach_money
      colorValue: 0xFF2D8A4E,
      isDefault: true,
    ),
    const Category(
      id: 'cat_freelance',
      name: 'Freelance & Bonus',
      type: CategoryType.income,
      iconCode: 0xe3ae, // laptop_mac
      colorValue: 0xFF0F867C,
      isDefault: true,
    ),
    const Category(
      id: 'cat_investment',
      name: 'Investments & Dividends',
      type: CategoryType.income,
      iconCode: 0xf0204, // trending_up
      colorValue: 0xFFC5A059,
      isDefault: true,
    ),
    const Category(
      id: 'cat_other_income',
      name: 'Other Income',
      type: CategoryType.income,
      iconCode: 0xf184, // savings
      colorValue: 0xFF3F77B0,
      isDefault: true,
    ),

    // Expense
    const Category(
      id: 'cat_food',
      name: 'Food & Dining',
      type: CategoryType.expense,
      iconCode: 0xe532, // restaurant
      colorValue: 0xFFD35E4B,
      isDefault: true,
    ),
    const Category(
      id: 'cat_groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      iconCode: 0xe59c, // shopping_cart
      colorValue: 0xFF2D8A4E,
      isDefault: true,
    ),
    const Category(
      id: 'cat_transport',
      name: 'Transport & Fuel',
      type: CategoryType.expense,
      iconCode: 0xe1d7, // directions_car
      colorValue: 0xFF3F77B0,
      isDefault: true,
    ),
    const Category(
      id: 'cat_housing',
      name: 'Housing & Rent',
      type: CategoryType.expense,
      iconCode: 0xe318, // home
      colorValue: 0xFFC5A059,
      isDefault: true,
    ),
    const Category(
      id: 'cat_utilities',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      iconCode: 0xe3e8, // lightbulb
      colorValue: 0xFFD9822B,
      isDefault: true,
    ),
    const Category(
      id: 'cat_entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      iconCode: 0xe410, // movie
      colorValue: 0xFF8860B8,
      isDefault: true,
    ),
    const Category(
      id: 'cat_healthcare',
      name: 'Healthcare & Medical',
      type: CategoryType.expense,
      iconCode: 0xe3f1, // local_hospital
      colorValue: 0xFFD34541,
      isDefault: true,
    ),
    const Category(
      id: 'cat_education',
      name: 'Education',
      type: CategoryType.expense,
      iconCode: 0xe559, // school
      colorValue: 0xFF0F867C,
      isDefault: true,
    ),
    const Category(
      id: 'cat_subscriptions',
      name: 'Subscriptions',
      type: CategoryType.expense,
      iconCode: 0xf022c, // subscriptions
      colorValue: 0xFF5C6BC0,
      isDefault: true,
    ),
    const Category(
      id: 'cat_shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      iconCode: 0xe59c, // shopping_bag
      colorValue: 0xFFE91E63,
      isDefault: true,
    ),
    const Category(
      id: 'cat_other_expense',
      name: 'General & Other',
      type: CategoryType.expense,
      iconCode: 0xe404, // more_horiz
      colorValue: 0xFF7A8B99,
      isDefault: true,
    ),
  ];
}
