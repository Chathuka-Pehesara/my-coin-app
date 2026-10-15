import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/export_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/coin_avatar.dart';
import '../auth/pin_setup_dialog.dart';
import '../categories/category_manager_screen.dart';
import 'currency_picker_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<AppStateProvider>();
    try {
      await ExportService.exportTransactionsToCsv(
        transactions: state.transactions,
        accounts: state.accounts,
        categories: state.categories,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final state = context.read<AppStateProvider>();
    try {
      await ExportService.createJsonBackup(
        accounts: state.accounts,
        categories: state.categories,
        transactions: state.transactions,
        budgets: state.budgets,
        goals: state.savingsGoals,
        recurring: state.recurringTransactions,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restore from JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported JSON backup text below to restore all accounts, transactions, and budgets:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste JSON content here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final jsonText = controller.text.trim();
              if (jsonText.isEmpty) return;
              final success = await ExportService.restoreFromJsonString(jsonText);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

              if (context.mounted) {
                if (success) {
                  await context.read<AppStateProvider>().loadAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data restored successfully!')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid backup JSON format.')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reset All Financial Data?'),
        content: const Text(
          'This will erase all custom transactions, accounts, budgets, and savings goals and re-seed clean starter data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseCoral),
            onPressed: () async {
              await context.read<AppStateProvider>().resetAllData();
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database reset to clean defaults.')),
                );
              }
            },
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final authProv = context.watch<AuthProvider>();

    final currencyInfo = CurrencyFormatter.getCurrencyInfo(state.currencyCode);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Branding Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  const CoinAvatar(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Trans Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Version 1.0.0 • Local Ledger',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // General Preferences
            _buildSectionHeader('General Preferences', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.goldDark),
                    title: const Text('Default Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('${currencyInfo.flag} ${currencyInfo.code} (${currencyInfo.name})', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => CurrencyPickerDialog(
                          currentCurrency: state.currencyCode,
                          onSelected: (code) => state.setCurrency(code),
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: const Icon(Icons.category_outlined, color: AppColors.goldDark),
                    title: const Text('Category Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('${state.categories.length} active categories', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.goldDark),
                    title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(themeProv.isDarkMode ? 'Dark theme enabled' : 'Light theme (default)', style: const TextStyle(fontSize: 12)),
                    value: themeProv.isDarkMode,
                    activeThumbColor: AppColors.goldPrimary,
                    onChanged: (_) => themeProv.toggleTheme(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security & Privacy
            _buildSectionHeader('Security & Biometrics', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline_rounded, color: AppColors.goldDark),
                    title: const Text('PIN App Protection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(authProv.isPinEnabled ? 'PIN lock active' : 'Disabled', style: const TextStyle(fontSize: 12)),
                    value: authProv.isPinEnabled,
                    activeThumbColor: AppColors.goldPrimary,
                    onChanged: (val) {
                      if (val) {
                        showDialog(context: context, builder: (_) => const PinSetupDialog());
                      } else {
                        authProv.disablePin();
                      }
                    },
                  ),
                  if (authProv.isPinEnabled && authProv.canUseBiometrics) ...[
                    _buildDivider(isDark),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.goldDark),
                      title: const Text('Biometric Unlock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Use fingerprint or face recognition', style: TextStyle(fontSize: 12)),
                      value: authProv.isBiometricEnabled,
                      activeThumbColor: AppColors.goldPrimary,
                      onChanged: (val) => authProv.setBiometrics(val),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Export
            _buildSectionHeader('Data Management & Backups', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.incomeGreen),
                    title: const Text('Export Records to CSV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Download complete spreadsheet of your ledger', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.share_outlined, size: 20),
                    onTap: () => _exportCsv(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.transferBlue),
                    title: const Text('Full JSON Database Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Complete backup of all accounts, budgets, and goals', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.share_outlined, size: 20),
                    onTap: () => _exportBackup(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.goldDark),
                    title: const Text('Restore from Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Import existing JSON backup snapshot', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showRestoreDialog(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: AppColors.expenseCoral),
                    title: const Text('Reset All Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.expenseCoral)),
                    subtitle: const Text('Erase custom records and re-seed defaults', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.expenseCoral),
                    onTap: () => _confirmResetData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Privacy disclosure note
            Center(
              child: Text(
                '🔒 All financial records are stored securely on your local device.\nNo external tracking, no cloud telemetry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.cardBorder);
  }
}
