import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/coin_avatar.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometrics();
    });
  }

  Future<void> _tryBiometrics() async {
    final auth = context.read<AuthProvider>();
    if (auth.isBiometricEnabled && auth.canUseBiometrics) {
      await auth.unlockWithBiometrics();
    }
  }

  void _onDigitPressed(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _hasError = false;
        _pin += digit;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.unlockWithPin(_pin);
    if (!success && mounted) {
      setState(() {
        _hasError = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),
              const CoinAvatar(size: 64),
              const SizedBox(height: 16),
              Text(
                'My Trans Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _hasError ? 'Incorrect PIN. Please try again.' : 'Enter your 4-digit security PIN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hasError
                      ? AppColors.expenseCoral
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? (_hasError ? AppColors.expenseCoral : AppColors.goldPrimary)
                            : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? AppColors.expenseCoral
                              : (isFilled ? AppColors.goldPrimary : (isDark ? AppColors.darkBorder : AppColors.cardBorder)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(flex: 2),

              // Keypad
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3'], isDark),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['4', '5', '6'], isDark),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['7', '8', '9'], isDark),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Biometrics button
                        auth.isBiometricEnabled
                            ? InkWell(
                                onTap: _tryBiometrics,
                                borderRadius: BorderRadius.circular(36),
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? AppColors.darkSurface : Colors.white,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    color: AppColors.goldDark,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const SizedBox(width: 68),

                        _buildKeypadButton('0', isDark),

                        // Backspace button
                        InkWell(
                          onTap: _onDeletePressed,
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.backspace_outlined,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildKeypadButton(d, isDark)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, bool isDark) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
