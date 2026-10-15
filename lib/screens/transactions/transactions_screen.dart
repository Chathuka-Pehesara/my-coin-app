import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_record.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/empty_state_view.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final state = context.read<AppStateProvider>();
    final initialRange = (state.filterStartDate != null && state.filterEndDate != null)
        ? DateTimeRange(start: state.filterStartDate!, end: state.filterEndDate!)
        : DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      state.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final transactions = state.filteredTransactions;

    // Group transactions by day
    final grouped = <DateTime, List<TransactionRecord>>{};
    for (final tx in transactions) {
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dayKey, () => []).add(tx);
    }
    final sortedDayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.tune_rounded,
              color: (_showFilters || state.filterType != null || state.filterCategoryId != null || state.filterAccountId != null || state.filterStartDate != null)
                  ? AppColors.goldDark
                  : null,
            ),
            tooltip: 'Filter Records',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => state.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search title, merchant, or notes...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          state.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Collapsible Advanced Filter Section
          if (_showFilters) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Types', state.filterType == null, () => state.setFilterType(null)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Expenses', state.filterType == TransactionType.expense, () => state.setFilterType(TransactionType.expense)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Income', state.filterType == TransactionType.income, () => state.setFilterType(TransactionType.income)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Transfers', state.filterType == TransactionType.transfer, () => state.setFilterType(TransactionType.transfer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category & Account Dropdowns
                  Row(
                    children: [
                      // Category
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(state.filterCategoryId),
                          initialValue: state.filterCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories', style: TextStyle(fontSize: 12))),
                            ...state.categories.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                )),
                          ],
                          onChanged: (val) => state.setFilterCategory(val),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Account
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(state.filterAccountId),
                          initialValue: state.filterAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Account',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Accounts', style: TextStyle(fontSize: 12))),
                            ...state.accounts.map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                )),
                          ],
                          onChanged: (val) => state.setFilterAccount(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date range & Reset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _pickDateRange(context),
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          (state.filterStartDate != null && state.filterEndDate != null)
                              ? '${AppDateUtils.formatShort(state.filterStartDate!)} - ${AppDateUtils.formatShort(state.filterEndDate!)}'
                              : 'Select Date Range',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          state.resetFilters();
                        },
                        child: const Text('Reset Filters', style: TextStyle(fontSize: 12, color: AppColors.expenseCoral)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Results counter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactions.length} ${transactions.length == 1 ? 'record' : 'records'} found',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                PopupMenuButton<TransactionSortOption>(
                  initialValue: state.sortOption,
                  onSelected: (val) => state.setSortOption(val),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 16, color: AppColors.goldDark),
                      const SizedBox(width: 4),
                      Text(
                        state.sortOption.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (context) => TransactionSortOption.values.map((opt) {
                    return PopupMenuItem(
                      value: opt,
                      child: Text(opt.displayName, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Grouped Transaction List
          Expanded(
            child: transactions.isEmpty
                ? EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Found',
                    message: 'No financial records match your current search query or filter criteria.',
                    actionLabel: 'Record Transaction',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: sortedDayKeys.length,
                    itemBuilder: (context, index) {
                      final dayKey = sortedDayKeys[index];
                      final dayTransactions = grouped[dayKey]!;

                      // Compute day total
                      final dayExpenses = dayTransactions
                          .where((t) => t.type == TransactionType.expense)
                          .fold(0.0, (sum, t) => sum + t.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppDateUtils.formatDayHeader(dayKey),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                if (dayExpenses > 0)
                                  Text(
                                    '-${CurrencyFormatter.format(dayExpenses, currencyCode: state.currencyCode, isMasked: state.isBalanceMasked)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.expenseCoral,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ...dayTransactions.map((tx) {
                            final category = state.categories.firstWhere(
                              (c) => c.id == tx.categoryId,
                              orElse: () => state.categories.first,
                            );
                            final account = state.accounts.firstWhere(
                              (a) => a.id == tx.accountId,
                              orElse: () => state.accounts.first,
                            );
                            final toAccount = tx.toAccountId != null
                                ? state.accounts.firstWhere(
                                    (a) => a.id == tx.toAccountId,
                                    orElse: () => state.accounts.first,
                                  )
                                : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Dismissible(
                                key: Key(tx.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseCoral,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  state.deleteTransaction(tx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${tx.title}"'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () => state.addTransaction(tx),
                                      ),
                                    ),
                                  );
                                },
                                child: TransactionTile(
                                  transaction: tx,
                                  category: category,
                                  account: account,
                                  toAccount: toAccount,
                                  currencyCode: state.currencyCode,
                                  isMasked: state.isBalanceMasked,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDetailScreen(transaction: tx),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: AppColors.textOnGold,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Record', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.goldSubtle,
      checkmarkColor: AppColors.goldDark,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.goldDark : AppColors.textSecondary,
      ),
    );
  }
}
