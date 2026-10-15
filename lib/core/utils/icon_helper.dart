import 'package:flutter/material.dart';

class IconHelper {
  static const Map<int, IconData> _iconMap = {
    // Account icons
    0xe040: Icons.attach_money,
    0xe041: Icons.account_balance_wallet,
    0xf184: Icons.savings,
    0xe19f: Icons.credit_card,
    0xe042: Icons.account_balance,
    0xe6a8: Icons.wallet,

    // Category icons
    0xe3ae: Icons.laptop_mac,
    0xf0204: Icons.trending_up,
    0xe532: Icons.restaurant,
    0xe59c: Icons.shopping_cart,
    0xe1d7: Icons.directions_car,
    0xe318: Icons.home,
    0xe3e8: Icons.lightbulb,
    0xe410: Icons.movie,
    0xe3f1: Icons.local_hospital,
    0xe559: Icons.school,
    0xf022c: Icons.subscriptions,
    0xe404: Icons.more_horiz,
    0xe299: Icons.flight,
    0xe28d: Icons.fitness_center,
    0xe199: Icons.coffee,
    0xe4a1: Icons.pets,
    0xe13c: Icons.card_giftcard,
    0xe6f2: Icons.work,
  };

  static IconData getIcon(int codePoint, [IconData fallback = Icons.category_outlined]) {
    return _iconMap[codePoint] ?? fallback;
  }
}
