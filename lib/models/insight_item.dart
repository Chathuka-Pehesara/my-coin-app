import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum InsightType {
  warning,
  positive,
  tip,
  unusual,
  neutral;

  Color get color {
    switch (this) {
      case InsightType.warning:
        return AppColors.expenseCoral;
      case InsightType.positive:
        return AppColors.incomeGreen;
      case InsightType.tip:
        return AppColors.goldDark;
      case InsightType.unusual:
        return Colors.deepOrange;
      case InsightType.neutral:
        return AppColors.savingsTeal;
    }
  }

  Color get lightColor {
    switch (this) {
      case InsightType.warning:
        return AppColors.expenseCoralLight;
      case InsightType.positive:
        return AppColors.incomeGreenLight;
      case InsightType.tip:
        return AppColors.goldSubtle;
      case InsightType.unusual:
        return const Color(0xFFFFF3E0);
      case InsightType.neutral:
        return AppColors.savingsTealLight;
    }
  }

  IconData get icon {
    switch (this) {
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.positive:
        return Icons.trending_up_rounded;
      case InsightType.tip:
        return Icons.lightbulb_outline_rounded;
      case InsightType.unusual:
        return Icons.radar_rounded;
      case InsightType.neutral:
        return Icons.auto_graph_rounded;
    }
  }
}

class InsightItem {
  final String id;
  final String title;
  final String message;
  final InsightType type;
  final double? metricValue;
  final String? relatedId;
  final DateTime generatedAt;

  InsightItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.metricValue,
    this.relatedId,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}
