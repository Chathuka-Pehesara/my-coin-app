import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';

/// Premium 3D Perspective Tilt Balance Card with specular glare and holographic parallax coin
class BalanceCard extends StatefulWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final String currencyCode;
  final bool isMasked;
  final VoidCallback onToggleMask;
  final VoidCallback onAddTransaction;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.currencyCode,
    required this.isMasked,
    required this.onToggleMask,
    required this.onAddTransaction,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _tiltXAnim;
  late Animation<double> _tiltYAnim;

  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;
  double _coinRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tiltXAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _tiltYAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _springController.addListener(() {
      setState(() {
        _currentTiltX = _tiltXAnim.value;
        _currentTiltY = _tiltYAnim.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    if (size.width == 0 || size.height == 0) return;
    _springController.stop();

    // Map position to -1.0 .. +1.0 relative to center
    final dx = (localPosition.dx - (size.width / 2)) / (size.width / 2);
    final dy = (localPosition.dy - (size.height / 2)) / (size.height / 2);

    setState(() {
      // Tilt angles (clamped to realistic 3D bounds)
      _currentTiltX = (-dy * 0.14).clamp(-0.16, 0.16);
      _currentTiltY = (dx * 0.14).clamp(-0.16, 0.16);
    });
  }

  void _onPanEnd() {
    _tiltXAnim = Tween<double>(begin: _currentTiltX, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    );
    _tiltYAnim = Tween<double>(begin: _currentTiltY, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    );
    _springController.forward(from: 0.0);
  }

  void _spinCoinBadge() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    setState(() {
      _coinRotation += 2 * pi;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 3D perspective matrix
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // Perspective depth
      ..rotateX(_currentTiltX)
      ..rotateY(_currentTiltY);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, 200);

        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details.localPosition, cardSize),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: () => _onPanEnd(),
          child: MouseRegion(
            onHover: (event) => _onPanUpdate(event.localPosition, cardSize),
            onExit: (_) => _onPanEnd(),
            child: Transform(
              alignment: FractionalOffset.center,
              transform: transform,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Metallic / Obsidian Card Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? AppColors.goldPrimary.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: Offset(-_currentTiltY * 20, 8 + _currentTiltX * 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Dynamic Specular Metallic Glare Overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      _currentTiltY * 2.5 - 0.5,
                                      _currentTiltX * 2.5 - 0.5,
                                    ),
                                    end: Alignment(
                                      -_currentTiltY * 2.5 + 0.5,
                                      -_currentTiltX * 2.5 + 0.5,
                                    ),
                                    colors: [
                                      (isDark ? Colors.white : AppColors.goldLight)
                                          .withValues(
                                        alpha: (0.04 + (_currentTiltX.abs() + _currentTiltY.abs()) * 0.45)
                                            .clamp(0.0, 0.28),
                                      ),
                                      Colors.transparent,
                                      (isDark ? AppColors.goldPrimary : Colors.white)
                                          .withValues(
                                        alpha: (0.02 + (_currentTiltX.abs() + _currentTiltY.abs()) * 0.3)
                                            .clamp(0.0, 0.20),
                                      ),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Card Contents
                          Column(
                            children: [
                              // Upper header section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.goldPrimary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'TOTAL NET BALANCE',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.1,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: widget.onToggleMask,
                                              borderRadius: BorderRadius.circular(16),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      widget.isMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                      size: 16,
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      widget.isMasked ? 'Reveal' : 'Mask',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Holographic Coin Badge
                                            GestureDetector(
                                              onTap: _spinCoinBadge,
                                              child: TweenAnimationBuilder<double>(
                                                tween: Tween<double>(begin: 0, end: _coinRotation),
                                                duration: const Duration(milliseconds: 650),
                                                curve: Curves.easeOutBack,
                                                builder: (context, rot, child) {
                                                  return Transform(
                                                    alignment: Alignment.center,
                                                    transform: Matrix4.identity()..rotateY(rot),
                                                    child: child,
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.goldSubtle.withValues(alpha: 0.8),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppColors.goldPrimary.withValues(alpha: 0.5),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.goldPrimary.withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Text('🪙', style: TextStyle(fontSize: 14)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey('${widget.totalBalance}_${widget.isMasked}'),
                                      tween: Tween<double>(
                                        begin: widget.isMasked ? 0 : widget.totalBalance * 0.7,
                                        end: widget.totalBalance,
                                      ),
                                      duration: const Duration(milliseconds: 700),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, animatedVal, _) {
                                        return Text(
                                          CurrencyFormatter.format(
                                            animatedVal,
                                            currencyCode: widget.currencyCode,
                                            isMasked: widget.isMasked,
                                          ),
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.0,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                              ),

                              // Lower Income / Expense bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1D1B) : AppColors.goldSubtle.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(23),
                                    bottomRight: Radius.circular(23),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Income
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: AppColors.incomeGreen.withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 16,
                                              color: AppColors.incomeGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'This Month Income',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                TweenAnimationBuilder<double>(
                                                  key: ValueKey('${widget.monthlyIncome}_${widget.isMasked}'),
                                                  tween: Tween<double>(
                                                    begin: widget.isMasked ? 0 : widget.monthlyIncome * 0.7,
                                                    end: widget.monthlyIncome,
                                                  ),
                                                  duration: const Duration(milliseconds: 700),
                                                  curve: Curves.easeOutCubic,
                                                  builder: (context, animatedVal, _) {
                                                    return Text(
                                                      CurrencyFormatter.format(
                                                        animatedVal,
                                                        currencyCode: widget.currencyCode,
                                                        isMasked: widget.isMasked,
                                                        decimalDigits: 0,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.incomeGreen,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      height: 32,
                                      width: 1,
                                      color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                                    ),

                                    // Expense
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 14),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: AppColors.expenseCoral.withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.arrow_upward_rounded,
                                                size: 16,
                                                color: AppColors.expenseCoral,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'This Month Spend',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  TweenAnimationBuilder<double>(
                                                    key: ValueKey('${widget.monthlyExpenses}_${widget.isMasked}'),
                                                    tween: Tween<double>(
                                                      begin: widget.isMasked ? 0 : widget.monthlyExpenses * 0.7,
                                                      end: widget.monthlyExpenses,
                                                    ),
                                                    duration: const Duration(milliseconds: 700),
                                                    curve: Curves.easeOutCubic,
                                                    builder: (context, animatedVal, _) {
                                                      return Text(
                                                        CurrencyFormatter.format(
                                                          animatedVal,
                                                          currencyCode: widget.currencyCode,
                                                          isMasked: widget.isMasked,
                                                          decimalDigits: 0,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.expenseCoral,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
