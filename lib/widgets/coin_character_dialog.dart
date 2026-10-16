import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_record.dart';

/// Interactive Animated Coin Mascot ("Coiny") acting emotionally based on transaction type
class CoinCharacterReactionModal extends StatefulWidget {
  final TransactionRecord transaction;
  final String currencyCode;
  final bool isMasked;
  final VoidCallback? onDismissed;

  const CoinCharacterReactionModal({
    super.key,
    required this.transaction,
    required this.currencyCode,
    this.isMasked = false,
    this.onDismissed,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionRecord transaction,
    required String currencyCode,
    bool isMasked = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CoinCharacterReactionModal(
        transaction: transaction,
        currencyCode: currencyCode,
        isMasked: isMasked,
      ),
    );
  }

  @override
  State<CoinCharacterReactionModal> createState() => _CoinCharacterReactionModalState();
}

class _CoinCharacterReactionModalState extends State<CoinCharacterReactionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _autoDismissTimer;
  double _dismissProgress = 1.0;
  Timer? _progressTimer;
  int _pokeCount = 0;

  final Random _random = Random();
  late String _mascotSpeech;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _mascotSpeech = _getRandomPhrase(widget.transaction.type);

    // Auto-dismiss countdown (2.8 seconds total)
    const totalMs = 2800;
    const intervalMs = 50;
    int elapsed = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsed += intervalMs;
      if (mounted) {
        setState(() {
          _dismissProgress = (1.0 - (elapsed / totalMs)).clamp(0.0, 1.0);
        });
      }
    });

    _autoDismissTimer = Timer(const Duration(milliseconds: totalMs), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismissed?.call();
      }
    });

    try {
      if (widget.transaction.type == TransactionType.income) {
        HapticFeedback.lightImpact();
      } else if (widget.transaction.type == TransactionType.expense) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    _autoDismissTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  String _getRandomPhrase(TransactionType type) {
    if (type == TransactionType.income) {
      final phrases = [
        'Cha-ching! Money in the bank! 🤑✨',
        'Stacking up! We are getting wealthier! 🚀',
        'Incoming treasure secured! Keep it flowing! 💰',
        'Look at that balance grow! Top tier energy! 👑',
      ];
      return phrases[_random.nextInt(phrases.length)];
    } else if (type == TransactionType.expense) {
      final phrases = [
        'Ouch! My little gold chest felt that! 💸🥺',
        'Money spent! Please tell me it was worth it! 📉',
        'Goodbye little coin friends... spend wisely! 🙈',
        'A necessary expense, or a dangerous craving? 🧐',
      ];
      return phrases[_random.nextInt(phrases.length)];
    } else {
      final phrases = [
        'Smooth tactical repositioning! 🔄🏦',
        'Funds transferred across vaults safely! 😎',
        'Smart liquidity routing! Looking sharp! ⚡',
      ];
      return phrases[_random.nextInt(phrases.length)];
    }
  }

  void _onPokeMascot() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    setState(() {
      _pokeCount++;
      if (widget.transaction.type == TransactionType.income) {
        _mascotSpeech = _pokeCount.isEven
            ? 'Wheee! Coin rain! 🌟🪙'
            : 'More gold! More power! 👑';
      } else if (widget.transaction.type == TransactionType.expense) {
        _mascotSpeech = _pokeCount.isEven
            ? 'Don\'t poke me, save your coins! 🥺'
            : 'I\'m shedding gold tears here! 😭💸';
      } else {
        _mascotSpeech = 'Vault swap complete! 🕶️✨';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final type = widget.transaction.type;
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    if (type == TransactionType.income) {
      accentColor = AppColors.incomeGreen;
      typeLabel = 'Income Added';
      typeIcon = Icons.arrow_downward_rounded;
    } else if (type == TransactionType.expense) {
      accentColor = AppColors.expenseCoral;
      typeLabel = 'Expense Logged';
      typeIcon = Icons.arrow_upward_rounded;
    } else {
      accentColor = AppColors.transferBlue;
      typeLabel = 'Transfer Recorded';
      typeIcon = Icons.swap_horiz_rounded;
    }

    final formattedAmount = CurrencyFormatter.format(
      widget.transaction.amount,
      currencyCode: widget.currencyCode,
      isMasked: widget.isMasked,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auto-dismiss countdown line
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _dismissProgress,
              minHeight: 3,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 18),

          // Speech Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _mascotSpeech,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Animated Mascot Character
          GestureDetector(
            onTap: _onPokeMascot,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _CoinMascotPainter(
                      progress: _animController.value,
                      type: type,
                      isDark: isDark,
                      pokeOffset: _pokeCount % 2 == 1,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Transaction Summary Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(typeIcon, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.transaction.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${type == TransactionType.income ? '+' : (type == TransactionType.expense ? '-' : '')}$formattedAmount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm / Got it button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismissed?.call();
              },
              child: const Text('Got It! ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector CustomPainter that animates the live coin character and facial expressions
class _CoinMascotPainter extends CustomPainter {
  final double progress;
  final TransactionType type;
  final bool isDark;
  final bool pokeOffset;

  _CoinMascotPainter({
    required this.progress,
    required this.type,
    required this.isDark,
    required this.pokeOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    // Bouncing squash and stretch motion
    final double bounceY = (type == TransactionType.income)
        ? -8.0 * sin(progress * pi)
        : (type == TransactionType.expense)
            ? 3.0 * sin(progress * 4 * pi) // trembling
            : 0.0;

    final double cy = (size.height / 2) + bounceY;
    final double radius = 48.0;

    // 1. Particle Effects Behind Coin
    if (type == TransactionType.income) {
      _drawCelebrationConfetti(canvas, cx, cy);
    } else if (type == TransactionType.expense) {
      _drawTeardropsAndSweat(canvas, cx, cy);
    } else {
      _drawPortalRings(canvas, cx, cy);
    }

    // 2. 3D Bevelled Metallic Coin Base
    final coinCenter = Offset(cx, cy);

    // Drop shadow
    canvas.drawCircle(
      coinCenter.translate(0, 8),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Outer Rim Gradient
    final rimPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [
          AppColors.goldLight,
          AppColors.goldPrimary,
          AppColors.goldDark,
        ],
      ).createShader(Rect.fromCircle(center: coinCenter, radius: radius));

    canvas.drawCircle(coinCenter, radius, rimPaint);

    // Inner Coin Face
    final facePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF2C2),
          AppColors.goldLight,
          AppColors.goldPrimary,
        ],
      ).createShader(Rect.fromCircle(center: coinCenter, radius: radius - 6));

    canvas.drawCircle(coinCenter, radius - 6, facePaint);

    // Inner Rim Stamping line
    final stampPaint = Paint()
      ..color = AppColors.goldDark.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(coinCenter, radius - 7, stampPaint);

    // 3. Facial Expressions Based on Emotional State
    if (type == TransactionType.income) {
      _drawHappyFace(canvas, coinCenter);
      _drawCrown(canvas, coinCenter.translate(0, -radius - 4));
    } else if (type == TransactionType.expense) {
      _drawSadFace(canvas, coinCenter);
    } else {
      _drawCoolTransferFace(canvas, coinCenter);
    }

    // 4. Specular Curved Glass Shine across coin
    final shinePath = Path()
      ..moveTo(cx - 30, cy - radius + 12)
      ..quadraticBezierTo(cx + 25, cy - radius + 18, cx + 34, cy - 6)
      ..quadraticBezierTo(cx + 20, cy - radius + 32, cx - 30, cy - radius + 12);

    canvas.drawPath(
      shinePath,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _drawHappyFace(Canvas canvas, Offset center) {
    // Starry sparkling eyes
    _drawStarEye(canvas, center.translate(-16, -6), 7.0);
    _drawStarEye(canvas, center.translate(16, -6), 7.0);

    // Rosy pink cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.6);
    canvas.drawCircle(center.translate(-22, 10), 5.5, cheekPaint);
    canvas.drawCircle(center.translate(22, 10), 5.5, cheekPaint);

    // Big happy open grin
    final mouthPath = Path()
      ..moveTo(center.dx - 14, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 24, center.dx + 14, center.dy + 8)
      ..close();

    final mouthPaint = Paint()..color = const Color(0xFF6B1D2F);
    canvas.drawPath(mouthPath, mouthPaint);

    // Tongue
    final tonguePaint = Paint()..color = const Color(0xFFFF6B81);
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(center.translate(0, 16), 8, tonguePaint);
    canvas.restore();
  }

  void _drawStarEye(Canvas canvas, Offset pos, double r) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final double outerAngle = i * (pi / 2);
      final double innerAngle = outerAngle + (pi / 4);

      if (i == 0) {
        path.moveTo(pos.dx + cos(outerAngle) * r, pos.dy + sin(outerAngle) * r);
      } else {
        path.lineTo(pos.dx + cos(outerAngle) * r, pos.dy + sin(outerAngle) * r);
      }
      path.lineTo(pos.dx + cos(innerAngle) * (r * 0.35), pos.dy + sin(innerAngle) * (r * 0.35));
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF4A2800),
    );
    canvas.drawCircle(
      pos.translate(1, -1),
      r * 0.25,
      Paint()..color = Colors.white,
    );
  }

  void _drawSadFace(Canvas canvas, Offset center) {
    // Big teary glossy anime eyes
    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final eyeHighlight = Paint()..color = Colors.white;

    // Left eye
    canvas.drawCircle(center.translate(-15, -4), 8.5, eyePaint);
    canvas.drawCircle(center.translate(-17, -7), 3.5, eyeHighlight);
    canvas.drawCircle(center.translate(-13, -2), 1.8, eyeHighlight);

    // Right eye
    canvas.drawCircle(center.translate(15, -4), 8.5, eyePaint);
    canvas.drawCircle(center.translate(13, -7), 3.5, eyeHighlight);
    canvas.drawCircle(center.translate(17, -2), 1.8, eyeHighlight);

    // Worried downturned eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF5A3A00)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center.translate(-22, -16), center.translate(-10, -12), browPaint);
    canvas.drawLine(center.translate(22, -16), center.translate(10, -12), browPaint);

    // Quivering wavy sad mouth
    final mouthPath = Path()
      ..moveTo(center.dx - 12, center.dy + 16)
      ..quadraticBezierTo(center.dx - 6, center.dy + 10, center.dx, center.dy + 13)
      ..quadraticBezierTo(center.dx + 6, center.dy + 10, center.dx + 12, center.dy + 16);

    final mouthOutline = Paint()
      ..color = const Color(0xFF5A3A00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(mouthPath, mouthOutline);
  }

  void _drawCoolTransferFace(Canvas canvas, Offset center) {
    // Cool black shades / sunglasses
    final glassPaint = Paint()..color = const Color(0xFF1A1A24);
    final leftGlass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(-16, -5), width: 26, height: 16),
      const Radius.circular(5),
    );
    final rightGlass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(16, -5), width: 26, height: 16),
      const Radius.circular(5),
    );

    canvas.drawRRect(leftGlass, glassPaint);
    canvas.drawRRect(rightGlass, glassPaint);

    // Bridge of glasses
    canvas.drawLine(
      center.translate(-3, -5),
      center.translate(3, -5),
      Paint()
        ..color = const Color(0xFF1A1A24)
        ..strokeWidth = 2.5,
    );

    // Glint reflection line across sunglasses
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(center.translate(-24, -10), center.translate(-14, 0), glintPaint);
    canvas.drawLine(center.translate(8, -10), center.translate(18, 0), glintPaint);

    // Confident smirk
    final smirkPath = Path()
      ..moveTo(center.dx - 8, center.dy + 14)
      ..quadraticBezierTo(center.dx + 4, center.dy + 16, center.dx + 12, center.dy + 10);

    canvas.drawPath(
      smirkPath,
      Paint()
        ..color = const Color(0xFF5A3A00)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCrown(Canvas canvas, Offset pos) {
    final crownPath = Path()
      ..moveTo(pos.dx - 18, pos.dy)
      ..lineTo(pos.dx - 22, pos.dy - 16)
      ..lineTo(pos.dx - 9, pos.dy - 8)
      ..lineTo(pos.dx, pos.dy - 20)
      ..lineTo(pos.dx + 9, pos.dy - 8)
      ..lineTo(pos.dx + 22, pos.dy - 16)
      ..lineTo(pos.dx + 18, pos.dy)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
      ).createShader(Rect.fromCenter(center: pos, width: 44, height: 24));

    canvas.drawPath(crownPath, crownPaint);

    // Tiny jewels on crown
    final jewelPaint = Paint()..color = const Color(0xFFFF3366);
    canvas.drawCircle(pos.translate(0, -20), 2.5, jewelPaint);
    canvas.drawCircle(pos.translate(-22, -16), 2.0, jewelPaint);
    canvas.drawCircle(pos.translate(22, -16), 2.0, jewelPaint);
  }

  void _drawCelebrationConfetti(Canvas canvas, double cx, double cy) {
    final confettiPositions = [
      Offset(cx - 50, cy - 35),
      Offset(cx + 48, cy - 40),
      Offset(cx - 38, cy + 30),
      Offset(cx + 42, cy + 28),
      Offset(cx - 20, cy - 55),
      Offset(cx + 25, cy - 52),
    ];

    for (int i = 0; i < confettiPositions.length; i++) {
      final p = confettiPositions[i];
      final color = i.isEven ? AppColors.goldPrimary : const Color(0xFF00E676);
      canvas.drawCircle(p, 3.0 + (i % 2), Paint()..color = color);
    }
  }

  void _drawTeardropsAndSweat(Canvas canvas, double cx, double cy) {
    final tearPaint = Paint()..color = const Color(0xFF4FC3F7);

    // Animated teardrop falling from eye
    final tearY = cy + 6.0 + (progress * 24.0);
    canvas.drawCircle(Offset(cx - 15, tearY), 3.5, tearPaint);
    canvas.drawCircle(Offset(cx + 15, tearY), 3.5, tearPaint);

    // Sweat drop on top right forehead
    final sweatPath = Path()
      ..moveTo(cx + 34, cy - 32)
      ..quadraticBezierTo(cx + 40, cy - 24, cx + 34, cy - 20)
      ..quadraticBezierTo(cx + 28, cy - 24, cx + 34, cy - 32)
      ..close();

    canvas.drawPath(sweatPath, tearPaint);
  }

  void _drawPortalRings(Canvas canvas, double cx, double cy) {
    final ringPaint = Paint()
      ..color = AppColors.transferBlue.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 40),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinMascotPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pokeOffset != pokeOffset;
  }
}
