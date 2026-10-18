import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_state_provider.dart';

enum MascotMood {
  thriving, // High savings / zero spend streak
  balanced, // Normal steady budget
  caution,  // High spend today or near budget limit
}

/// Live interactive dashboard companion ("Coiny") reacting in real time to financial health
class DashboardMascotWidget extends StatefulWidget {
  const DashboardMascotWidget({super.key});

  @override
  State<DashboardMascotWidget> createState() => _DashboardMascotWidgetState();
}

class _DashboardMascotWidgetState extends State<DashboardMascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleAnim;
  late AnimationController _flipAnim;
  late AnimationController _celebrateAnim;

  int _tapCount = 0;
  String? _customQuote;
  final List<_MiniSparkle> _ambientSparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _idleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _flipAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _celebrateAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _generateAmbientSparkles();
  }

  void _generateAmbientSparkles() {
    _ambientSparkles.clear();
    for (int i = 0; i < 8; i++) {
      _ambientSparkles.add(
        _MiniSparkle(
          dx: -40.0 + _random.nextDouble() * 80.0,
          dy: -30.0 + _random.nextDouble() * 60.0,
          size: 2.0 + _random.nextDouble() * 3.5,
          color: i.isEven ? AppColors.goldPrimary : AppColors.goldLight,
        ),
      );
    }
  }

  @override
  void dispose() {
    _idleAnim.dispose();
    _flipAnim.dispose();
    _celebrateAnim.dispose();
    super.dispose();
  }

  void _onTapMascot(MascotMood mood) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    _flipAnim.forward(from: 0.0);
    _celebrateAnim.forward(from: 0.0);
    _generateAmbientSparkles();

    setState(() {
      _tapCount++;
      if (mood == MascotMood.thriving) {
        final quotes = [
          'You tapped me! High five for great wealth management! ✋🪙',
          'Compound interest is our secret superpower! 🚀',
          'Vault is gleaming! Keep stacking those coins! 👑',
          'Every rupee saved is an employee working for you! 💼✨',
        ];
        _customQuote = quotes[_tapCount % quotes.length];
      } else if (mood == MascotMood.caution) {
        final quotes = [
          'Easy on the card today! Let\'s defend our budget ceiling! 🛡️',
          'Delayed gratification = Future financial freedom! ⏳💰',
          'Take a deep breath before that next impulse purchase! 🧘‍♂️',
        ];
        _customQuote = quotes[_tapCount % quotes.length];
      } else {
        final quotes = [
          'Steady pacing! Consistency is the true key to freedom. 🧭',
          'Tracking every transaction keeps you 10 steps ahead! 📈',
          'Coiny is on watch! Your finances are in good hands. 👁️✨',
        ];
        _customQuote = quotes[_tapCount % quotes.length];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final income = state.currentMonthIncome;
    final expense = state.currentMonthExpenses;
    final net = income - expense;

    // Determine Coiny's live mood
    MascotMood mood;
    String statusTitle;
    Color statusColor;

    if (income > 0 && (net / income) >= 0.35) {
      mood = MascotMood.thriving;
      statusTitle = 'Vault Thriving (Saving ${(net / income * 100).toStringAsFixed(0)}%)';
      statusColor = AppColors.incomeGreen;
    } else if (expense > 0 && income > 0 && expense > income * 0.9) {
      mood = MascotMood.caution;
      statusTitle = 'Budget Alert (Expenses Pacing High)';
      statusColor = AppColors.expenseCoral;
    } else {
      mood = MascotMood.balanced;
      statusTitle = 'Steady Financial Rhythm';
      statusColor = AppColors.goldDark;
    }

    final quote = _customQuote ??
        (mood == MascotMood.thriving
            ? 'Awesome discipline! Your wealth stack is actively growing! 🌟'
            : mood == MascotMood.caution
                ? 'Watch out! Expenses are near your monthly intake limit! ⚠️'
                : 'Steady pacing! Ready to log and track your next transaction? 🪙');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Interactive Animated Coiny Mascot Bubble
          GestureDetector(
            onTap: () => _onTapMascot(mood),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient Sparkles
                  AnimatedBuilder(
                    animation: _idleAnim,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(72, 72),
                        painter: _SparkleCanvasPainter(
                          sparkles: _ambientSparkles,
                          progress: _idleAnim.value,
                        ),
                      );
                    },
                  ),

                  // Living 3D Coin Mascot with Physics Bouncing & 3D Flip
                  AnimatedBuilder(
                    animation: Listenable.merge([_idleAnim, _flipAnim]),
                    builder: (context, _) {
                      final bounce = sin(_idleAnim.value * pi) * 4.0;
                      final flip = _flipAnim.value;

                      return Transform.translate(
                        offset: Offset(0, -bounce),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(flip * 2 * pi),
                          child: CustomPaint(
                            size: const Size(54, 54),
                            painter: _MiniCoinMascotPainter(
                              mood: mood,
                              isDark: isDark,
                              progress: _idleAnim.value,
                              isFlipped: flip > 0.25 && flip < 0.75,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Speech Bubble & Financial Status
          Expanded(
            child: GestureDetector(
              onTap: () => _onTapMascot(mood),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Tap Coiny',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    quote,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkle {
  final double dx;
  final double dy;
  final double size;
  final Color color;

  _MiniSparkle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });
}

class _SparkleCanvasPainter extends CustomPainter {
  final List<_MiniSparkle> sparkles;
  final double progress;

  _SparkleCanvasPainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < sparkles.length; i++) {
      final s = sparkles[i];
      final alpha = (sin((progress * 2 * pi) + (i * 0.8)) * 0.5 + 0.5).clamp(0.1, 1.0);
      final paint = Paint()
        ..color = s.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cx + s.dx, cy + s.dy), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleCanvasPainter oldDelegate) => true;
}

class _MiniCoinMascotPainter extends CustomPainter {
  final MascotMood mood;
  final bool isDark;
  final double progress;
  final bool isFlipped;

  _MiniCoinMascotPainter({
    required this.mood,
    required this.isDark,
    required this.progress,
    required this.isFlipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = 24.0;
    final center = Offset(cx, cy);

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 4),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Outer rim gradient
    final rimPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.35),
        colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, rimPaint);

    // Inner face
    final facePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF6D8), AppColors.goldLight, AppColors.goldPrimary],
      ).createShader(Rect.fromCircle(center: center, radius: r - 3));

    canvas.drawCircle(center, r - 3, facePaint);

    if (isFlipped) {
      canvas.drawCircle(
        center,
        10,
        Paint()
          ..color = AppColors.goldDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      return;
    }

    // Facial expressions based on mood
    if (mood == MascotMood.thriving) {
      // Star sparkling eyes
      _drawStarEye(canvas, center.translate(-8, -3), 4.0);
      _drawStarEye(canvas, center.translate(8, -3), 4.0);

      // Pink blush
      final cheekPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.6);
      canvas.drawCircle(center.translate(-11, 4), 3.0, cheekPaint);
      canvas.drawCircle(center.translate(11, 4), 3.0, cheekPaint);

      // Big happy open smile
      final mouth = Path()
        ..moveTo(center.dx - 7, center.dy + 4)
        ..quadraticBezierTo(center.dx, center.dy + 13, center.dx + 7, center.dy + 4)
        ..close();
      canvas.drawPath(mouth, Paint()..color = const Color(0xFF5A1523));

      // Golden crown
      final crown = Path()
        ..moveTo(cx - 9, cy - r)
        ..lineTo(cx - 12, cy - r - 8)
        ..lineTo(cx - 5, cy - r - 4)
        ..lineTo(cx, cy - r - 10)
        ..lineTo(cx + 5, cy - r - 4)
        ..lineTo(cx + 12, cy - r - 8)
        ..lineTo(cx + 9, cy - r)
        ..close();
      canvas.drawPath(
        crown,
        Paint()
          ..shader = const LinearGradient(colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark])
              .createShader(Rect.fromCenter(center: Offset(cx, cy - r - 5), width: 24, height: 12)),
      );
    } else if (mood == MascotMood.caution) {
      // Worried glossy eyes
      final eyePaint = Paint()..color = const Color(0xFF2C3E50);
      canvas.drawCircle(center.translate(-8, -2), 4.5, eyePaint);
      canvas.drawCircle(center.translate(-9, -4), 1.8, Paint()..color = Colors.white);

      canvas.drawCircle(center.translate(8, -2), 4.5, eyePaint);
      canvas.drawCircle(center.translate(7, -4), 1.8, Paint()..color = Colors.white);

      // Cold sweat drop
      final sweat = Path()
        ..moveTo(cx + 14, cy - 14)
        ..quadraticBezierTo(cx + 17, cy - 10, cx + 14, cy - 7)
        ..quadraticBezierTo(cx + 11, cy - 10, cx + 14, cy - 14)
        ..close();
      canvas.drawPath(sweat, Paint()..color = const Color(0xFF4FC3F7));

      // Quivering mouth
      final mouth = Path()
        ..moveTo(center.dx - 6, center.dy + 8)
        ..quadraticBezierTo(center.dx - 3, center.dy + 5, center.dx, center.dy + 6.5)
        ..quadraticBezierTo(center.dx + 3, center.dy + 5, center.dx + 6, center.dy + 8);
      canvas.drawPath(
        mouth,
        Paint()
          ..color = const Color(0xFF5A3A00)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    } else {
      // Normal happy smiling eyes (arc)
      final eyePaint = Paint()
        ..color = const Color(0xFF4A2800)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCenter(center: center.translate(-8, -3), width: 8, height: 6),
        pi,
        pi,
        false,
        eyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: center.translate(8, -3), width: 8, height: 6),
        pi,
        pi,
        false,
        eyePaint,
      );

      // Cute smile
      final mouth = Path()
        ..moveTo(center.dx - 6, center.dy + 5)
        ..quadraticBezierTo(center.dx, center.dy + 11, center.dx + 6, center.dy + 5);
      canvas.drawPath(mouth, eyePaint);
    }

    // Specular shine
    canvas.drawLine(
      Offset(cx - 14, cy - r + 6),
      Offset(cx + 14, cy - r + 8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStarEye(Canvas canvas, Offset pos, double r) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final double outer = i * (pi / 2);
      final double inner = outer + (pi / 4);

      if (i == 0) {
        path.moveTo(pos.dx + cos(outer) * r, pos.dy + sin(outer) * r);
      } else {
        path.lineTo(pos.dx + cos(outer) * r, pos.dy + sin(outer) * r);
      }
      path.lineTo(pos.dx + cos(inner) * (r * 0.35), pos.dy + sin(inner) * (r * 0.35));
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF4A2800));
    canvas.drawCircle(pos.translate(0.5, -0.5), r * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MiniCoinMascotPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.mood != mood ||
        oldDelegate.isFlipped != isFlipped;
  }
}
