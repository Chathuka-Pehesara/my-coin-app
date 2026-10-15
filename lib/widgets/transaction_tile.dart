import 'package:flutter/material.dart';
import '../models/transaction_record.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionRecord transaction;
  final Category? category;
  final Account? account;
  final Account? toAccount;
  final String currencyCode;
  final bool isMasked;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.account,
    this.toAccount,
    required this.currencyCode,
    required this.isMasked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final catColor = category?.color ?? AppColors.goldPrimary;
    final catIcon = category?.icon ?? Icons.category_outlined;

    String subtitleText = '';
    if (transaction.type == TransactionType.transfer && toAccount != null) {
      subtitleText = '${account?.name ?? 'Account'} → ${toAccount?.name ?? 'Account'}';
    } else {
      final parts = <String>[];
      if (transaction.merchant != null && transaction.merchant!.isNotEmpty) {
        parts.add(transaction.merchant!);
      }
      if (account != null) {
        parts.add(account!.name);
      }
      subtitleText = parts.isNotEmpty ? parts.join(' • ') : (category?.name ?? 'General');
    }

    String amountPrefix = '';
    Color amountColor;
    if (transaction.type == TransactionType.income) {
      amountPrefix = '+';
      amountColor = AppColors.incomeGreen;
    } else if (transaction.type == TransactionType.expense) {
      amountPrefix = '-';
      amountColor = isDark ? const Color(0xFFFF6B6B) : AppColors.expenseCoral;
    } else {
      amountPrefix = '';
      amountColor = AppColors.transferBlue;
    }

    final formattedAmount = CurrencyFormatter.format(
      transaction.amount,
      currencyCode: currencyCode,
      isMasked: isMasked,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: catColor.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Icon(
                catIcon,
                size: 22,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount & Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix$formattedAmount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppDateUtils.formatShort(transaction.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
