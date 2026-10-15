import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class CurrencyPickerDialog extends StatelessWidget {
  final String currentCurrency;
  final ValueChanged<String> onSelected;

  const CurrencyPickerDialog({
    super.key,
    required this.currentCurrency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Choose Default Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: CurrencyFormatter.supportedCurrencies.values.map((info) {
            final isSelected = info.code == currentCurrency;
            return ListTile(
              leading: Text(info.flag, style: const TextStyle(fontSize: 24)),
              title: Text(
                '${info.code} - ${info.name}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.goldLight : AppColors.goldDark)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              trailing: Text(
                info.symbol,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              selected: isSelected,
              selectedTileColor: AppColors.goldSubtle,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                onSelected(info.code);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
