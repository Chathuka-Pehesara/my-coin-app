import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/savings_goal.dart';
import '../models/account.dart';
import '../providers/app_state_provider.dart';

class CoinDropModal extends StatefulWidget {
  final SavingsGoal goal;

  const CoinDropModal({
    super.key,
    required this.goal,
  });

  @override
  State<CoinDropModal> createState() => _CoinDropModalState();
}

class _CoinDropModalState extends State<CoinDropModal> with TickerProviderStateMixin {
  late AnimationController _dropController;
  late Animation<double> _dropAnimation;
  late AnimationController _sparkleController;

  late double _simulatedCurrentAmount;
  double _selectedDropAmount = 1000.0;
  String? _selectedAccountId;
  bool _isDropping = false;
  bool _justAchievedGoal = false;

  final List<double> _quickAmounts = [500.0, 1000.0, 2500.0, 5000.0, 10000.0];
  final List<_SparkleParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _simulatedCurrentAmount = widget.goal.currentAmount;

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _dropAnimation = CurvedAnimation(
      parent: _dropController,
      curve: Curves.bounceOut,
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _dropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onDropCompleted();
      }
    });
  }

  @override
  void dispose() {
    _dropController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _triggerCoinDrop() {
    if (_isDropping) return;

    setState(() {
      _isDropping = true;
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    _dropController.forward(from: 0.0);
  }

  void _generateSparkles() {
    _particles.clear();
    for (int i = 0; i < 18; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40.0 + _random.nextDouble() * 90.0;
      _particles.add(
        _SparkleParticle(
          dx: cos(angle) * speed,
          dy: sin(angle) * speed - 20.0,
          color: i.isEven ? AppColors.goldPrimary : AppColors.goldLight,
          size: 3.0 + _random.nextDouble() * 4.0,
        ),
      );
    }
    _sparkleController.forward(from: 0.0);
  }

  Future<void> _onDropCompleted() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _generateSparkles();

    final prevRatio = _simulatedCurrentAmount / widget.goal.targetAmount;
    final newAmount = _simulatedCurrentAmount + _selectedDropAmount;
    final newRatio = newAmount / widget.goal.targetAmount;

    setState(() {
      _simulatedCurrentAmount = newAmount;
      _isDropping = false;
      if (prevRatio < 1.0 && newRatio >= 1.0) {
        _justAchievedGoal = true;
      }
    });

    final state = context.read<AppStateProvider>();
    final accountId = _selectedAccountId ?? (state.accounts.isNotEmpty ? state.accounts.first.id : '');

    if (accountId.isNotEmpty) {
      await state.depositToGoal(
        goal: widget.goal.copyWith(currentAmount: _simulatedCurrentAmount - _selectedDropAmount),
        amount: _selectedDropAmount,
        fromAccountId: accountId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    if (_selectedAccountId == null && state.accounts.isNotEmpty) {
      _selectedAccountId = state.accounts.first.id;
    }

    final progressRatio = widget.goal.targetAmount > 0
        ? (_simulatedCurrentAmount / widget.goal.targetAmount).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Target Goal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(widget.goal.icon, size: 20, color: widget.goal.color),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.goal.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${CurrencyFormatter.format(widget.goal.targetAmount, currencyCode: state.currencyCode, decimalDigits: 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.savingsTealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progressRatio * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.savingsTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Milestone Banner if reached
            if (_justAchievedGoal || progressRatio >= 1.0)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldDark, AppColors.goldPrimary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Goal Target Achieved! Fantastic Work! 🏆',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Interactive Physics Savings Jar Canvas
            SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Sparkles
                  AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, _) {
                      if (_particles.isEmpty || !_sparkleController.isAnimating) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _SparklePainter(
                          particles: _particles,
                          progress: _sparkleController.value,
                        ),
                      );
                    },
                  ),

                  // The Glass Jar Painter
                  CustomPaint(
                    size: const Size(160, 180),
                    painter: _GlassJarPainter(
                      fillRatio: progressRatio,
                      isDark: isDark,
                      accentColor: widget.goal.color,
                    ),
                  ),

                  // Falling / Floating Animated Coin
                  AnimatedBuilder(
                    animation: _dropAnimation,
                    builder: (context, child) {
                      // Top starts at y = -70, lands inside jar at y = 30
                      final double startY = -75.0;
                      final double targetY = 35.0 - (progressRatio * 60.0);
                      final currentY = _isDropping
                          ? startY + (_dropAnimation.value * (targetY - startY))
                          : startY;

                      return Transform.translate(
                        offset: Offset(0, currentY),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                          _triggerCoinDrop();
                        }
                      },
                      child: _build3DGoldCoin(
                        amount: _selectedDropAmount,
                        currencyCode: state.currencyCode,
                      ),
                    ),
                  ),

                  // Drag hint when idle
                  if (!_isDropping)
                    Positioned(
                      top: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.goldDark),
                            SizedBox(width: 4),
                            Text(
                              'Swipe coin or tap button below to drop',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.goldDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Live Balance Preview
            Text(
              'Current Saved: ${CurrencyFormatter.format(_simulatedCurrentAmount, currencyCode: state.currencyCode, decimalDigits: 0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Quick Deposit Chips
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Coin Value to Drop:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((amt) {
                  final isSelected = _selectedDropAmount == amt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '+${CurrencyFormatter.format(amt, currencyCode: state.currencyCode, decimalDigits: 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.goldDark,
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDropAmount = amt);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Source Account Selector
            if (state.accounts.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Deduct From Account:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAccountId,
                    items: state.accounts.map((Account acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Row(
                          children: [
                            Icon(acc.icon, size: 16, color: acc.color),
                            const SizedBox(width: 8),
                            Expanded(child: Text(acc.name, style: const TextStyle(fontSize: 13))),
                            Text(
                              CurrencyFormatter.format(acc.balance, currencyCode: state.currencyCode, decimalDigits: 0),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedAccountId = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Drop Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isDropping ? null : _triggerCoinDrop,
                icon: const Icon(Icons.toll_rounded, size: 18),
                label: Text(
                  'Drop ${CurrencyFormatter.format(_selectedDropAmount, currencyCode: state.currencyCode, decimalDigits: 0)} Into Jar',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DGoldCoin({required double amount, required String currencyCode}) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [
            AppColors.goldLight,
            AppColors.goldPrimary,
            AppColors.goldDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldDark.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Glass Jar Painter with refractive highlights, lid, and fluid level
class _GlassJarPainter extends CustomPainter {
  final double fillRatio;
  final bool isDark;
  final Color accentColor;

  _GlassJarPainter({
    required this.fillRatio,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Jar body bounds
    final jarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.22, w * 0.70, h * 0.74),
      const Radius.circular(20),
    );

    // Jar neck / lid bounds
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.14, w * 0.48, h * 0.10),
      const Radius.circular(6),
    );

    // 1. Draw Liquid / Coin Fill Level
    final fillHeight = (h * 0.70) * fillRatio;
    final fillTop = (h * 0.94) - fillHeight;

    if (fillRatio > 0.01) {
      canvas.save();
      canvas.clipRRect(jarRect);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.65),
            AppColors.goldPrimary.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(w * 0.15, fillTop, w * 0.70, fillHeight));

      canvas.drawRect(
        Rect.fromLTWH(w * 0.15, fillTop, w * 0.70, fillHeight),
        fillPaint,
      );

      // Gold surface shimmer line
      final shimmerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(w * 0.15, fillTop),
        Offset(w * 0.85, fillTop),
        shimmerPaint,
      );

      canvas.restore();
    }

    // 2. Draw Jar Glass Background Tint
    final glassTintPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(jarRect, glassTintPaint);

    // 3. Draw Jar Glass Outline
    final outlinePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.35)
          : AppColors.goldDark.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(jarRect, outlinePaint);

    // 4. Draw Neck & Metallic Lid Rim
    final lidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
      ).createShader(Rect.fromLTWH(w * 0.26, h * 0.14, w * 0.48, h * 0.10))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(neckRect, lidPaint);

    final lidOutline = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(neckRect, lidOutline);

    // 5. Vertical Glass Refraction Highlights (Glass shine)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.22, h * 0.30),
      Offset(w * 0.22, h * 0.85),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassJarPainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}

class _SparkleParticle {
  final double dx;
  final double dy;
  final Color color;
  final double size;

  _SparkleParticle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_SparkleParticle> particles;
  final double progress;

  _SparklePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentPos = Offset(
        center.dx + (p.dx * progress),
        center.dy + (p.dy * progress),
      );

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(currentPos, p.size * (1.0 - (progress * 0.3)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
