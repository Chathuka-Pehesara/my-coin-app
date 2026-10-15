# My Trans Actions 🪙

> **A Premium Personal Finance Mobile Application Built with Flutter**

**My Trans Actions** is a personal finance tracking and wealth management mobile application. Designed with a coin-inspired fintech theme, it combines on-device privacy, financial calculation integrity, interactive analytics, and statistical spending intelligence.

---

## ✨ Key Capabilities

### 1. Financial Ledger & Calculations
- **Transaction Types**: Income, Expenses, and Transfers.
- **Account Transfer Integrity**: Transfers decrease the source account and increase the destination account without falsely skewing income or expense statistics.
- **Multi-Account Management**: Cash wallets, bank accounts, high-yield savings, and credit cards with negative liability tracking and net worth summaries.
- **Balance Masking**: Quick-toggle privacy mode on the dashboard to mask sensitive figures (`••••••`) in public spaces.

### 2. Statistical Financial Intelligence
- **Contextual Insights**: Generated dynamically from actual transaction records:
  - Month-over-month category percentage shifts.
  - Real-time monthly budget utilization and daily safe pacing.
  - Spending concentration warnings (e.g. top 3 categories share).
  - High savings rate milestones.
- **Unusual Transaction Detection**: Statistical outlier detection using category median baselines to identify anomalous expense spikes.
- **What-If Budget Simulator**: Interactive simulation model allowing users to adjust hypothetical category budgets and projected income to visualize monthly net cash flow and 1-year wealth accumulation in real time.

### 3. Interactive Analytics & Visualizations
- **Comparative Cash Flow**: Income vs. Expense bar chart powered by `fl_chart`.
- **Category Donut Chart**: Expense distribution with interactive touch selection, percentage tooltips, and legends.
- **Custom Time Periods**: Filter trends across *This Month*, *Last Month*, *Quarter*, *Year*, and *All Time*.
- **Category & Account Audit**: Largest transaction leaderboards and daily spending averages.

### 4. Budgets & Savings Goals
- **Budget Boundaries**: Overall monthly limits and category-specific targets with proactive alerts (*On Track*, *Near Limit*, *Exceeded*).
- **Savings Goals**: Goal target tracking (Emergency Funds, Tech Upgrades, Travel) with deadline countdowns and recommended monthly savings estimations.
- **Recurring Transactions**: Daily, weekly, monthly, and yearly recurring schedules for salaries, rent, and subscriptions with duplicate prevention and on-demand processing.

### 5. Security & Privacy
- **100% Local-First Ledger**: All records remain strictly on the device with SQLite database persistence and seamless in-memory fallback.
- **App Protection**: Local 4-digit PIN lock with optional biometric unlock (Fingerprint / Face ID).
- **Data Export & Backups**:
  - Full RFC 4180 CSV spreadsheet export with native sharing.
  - Complete JSON database backup and restore functionality.
- **Centralized Currency Formatter**: Initial default is **LKR (Sri Lankan Rupee, Rs.)**, fully configurable to USD, EUR, GBP, INR, and other world currencies.

---

## 🎨 Visual Identity & Theme

- **Primary Accent**: Champagne Gold & Light Coin Gold (`#C5A059`, `#DFBF77`)
- **Surfaces**: Warm Ivory (`#FAF8F5`) and Crisp White (`#FFFFFF`)
- **Typography**: Deep Charcoal (`#1E1D1A`) and Muted Gray (`#6B6760`)
- **Semantic Accents**:
  - Income: Balanced Green (`#2D8A4E`)
  - Expense: Coral Red (`#D34541`)
  - Savings: Soft Teal (`#0F867C`)
  - Transfers: Classic Blue (`#3273DC`)
- **Themes**: Light theme by default, with an optional sleek Warm Dark Mode.

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── theme/          # AppColors, AppTheme (Material 3)
│   ├── utils/          # CurrencyFormatter (LKR default), AppDateUtils
│   └── services/       # DatabaseService (SQLite), PreferencesService, BiometricService, ExportService, FinancialEngine
├── models/             # Account, Category, TransactionRecord, Budget, SavingsGoal, RecurringTransaction, InsightItem
├── providers/          # AppStateProvider (ChangeNotifier), ThemeProvider, AuthProvider
├── widgets/            # CoinAvatar, BalanceCard, TransactionTile, EmptyStateView
└── screens/
    ├── splash_gate_screen.dart
    ├── onboarding/     # OnboardingScreen
    ├── auth/           # PinLockScreen, PinSetupDialog
    ├── dashboard/      # DashboardScreen (Hero Card, Insights Carousel, Recent List)
    ├── transactions/   # TransactionsScreen, AddEditTransactionScreen, TransactionDetailScreen
    ├── accounts/       # AccountsScreen, AddEditAccountDialog
    ├── analytics/      # AnalyticsScreen, WhatIfSimulatorSheet
    ├── budgets_goals/  # BudgetsAndGoalsScreen, AddBudgetDialog, AddGoalDialog, GoalContributionDialog
    ├── categories/     # CategoryManagerScreen
    └── settings/       # SettingsScreen, CurrencyPickerDialog
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.44.0` or higher
- Dart SDK `^3.12.0` or higher
- Android SDK (for mobile builds)

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/my_trans_actions.git
cd "Trans Mobile app"

# Fetch packages
flutter pub get

# Run static analysis
flutter analyze

# Execute test suite
flutter test

# Run application locally
flutter run
```

---

## ⚙️ DevOps & CI/CD Pipeline

The project includes automated GitHub Actions continuous integration under `.github/workflows/build_apk.yml`:

- **Automated Verification**: Runs `flutter analyze` and `flutter test` on every push and pull request.
- **Release Build**: Automatically compiles a production release APK (`app-release.apk`).
- **Artifact Publishing**: Uploads the release APK as a downloadable workflow artifact (`my-trans-actions-release-apk`).
