import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_record.dart';

/// Interactive Coin Mascot Reaction Modal Sheet
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
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
    with TickerProviderStateMixin {
  // Idle breathing & floating controller
  late AnimationController _idleController;
  // Mascot 3D flip animation
  late AnimationController _flipController;

  // Mascot touch drag offset
  Offset _dragOffset = Offset.zero;

  // Coin blast particles
  final List<_CoinParticle> _coinParticles = [];
  Timer? _particleTimer;
  final Random _random = Random();

  Timer? _autoDismissTimer;
  double _dismissProgress = 1.0;
  Timer? _progressTimer;
  int _pokeCount = 0;
  late String _mascotSpeech;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _mascotSpeech = _getRandomPhrase(widget.transaction.type);

    // Initial burst of celebratory arcade coins
    _spawnCoins(count: 22);

    // Continuous physics update at ~60fps
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) {
        _tickParticles();
      }
    });

    // Auto-dismiss countdown (3.8 seconds so user can view mascot without feeling trapped)
    const totalMs = 3800;
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
      _finishAndClose();
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _idleController.dispose();
    _flipController.dispose();
    _particleTimer?.cancel();
    _autoDismissTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _spawnCoins({int count = 16}) {
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * (pi * 0.7);
      final speed = 120.0 + _random.nextDouble() * 220.0;

      _coinParticles.add(
        _CoinParticle(
          x: (_random.nextDouble() - 0.5) * 50,
          y: (_random.nextDouble() - 0.5) * 20,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 16.0 + _random.nextDouble() * 12.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotSpeed: (_random.nextDouble() - 0.5) * 8.0,
          opacity: 1.0,
          maxLife: 1.2 + _random.nextDouble() * 0.8,
        ),
      );
    }
  }

  void _tickParticles() {
    const dt = 0.016;

    setState(() {
      for (int i = _coinParticles.length - 1; i >= 0; i--) {
        final p = _coinParticles[i];
        p.age += dt;
        p.vy += 450.0 * dt; // gravity
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.rotation += p.rotSpeed * dt;
        p.opacity = (1.0 - (p.age / p.maxLife)).clamp(0.0, 1.0);

        if (p.age >= p.maxLife) {
          _coinParticles.removeAt(i);
        }
      }
    });
  }

  void _finishAndClose() {
    if (_isClosed) return;
    _isClosed = true;
    _particleTimer?.cancel();
    _autoDismissTimer?.cancel();
    _progressTimer?.cancel();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismissed?.call();
    }
  }

  void _onPokeCoiny() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _flipController.forward(from: 0.0);
    _spawnCoins(count: 18);

    setState(() {
      _pokeCount++;
      if (widget.transaction.type == TransactionType.income) {
        final phrases = [
          'Wheee! Coin shower! 🪙',
          'Stacking up the gold! 👑',
          'More wealth incoming! 🚀',
          'Vault boosted! 🪙',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else if (widget.transaction.type == TransactionType.expense) {
        final phrases = [
          'Protect the vault! 🛡️',
          'Watch the wallet! Stay steady! 🛡️',
          'Saving up is the true superpower! 💪',
          'Mindful spending makes you rich! 🧠',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else {
        final phrases = [
          'Vault swap confirmed! ⚡',
          'Hyperdrive transfer complete! 🔄',
          'Smooth tactical positioning! 😎',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      }
    });
  }

  String _getRandomPhrase(TransactionType type) {
    if (type == TransactionType.income) {
      return 'Cha-ching! Inflow secured! We\'re growing! 🤑';
    } else if (type == TransactionType.expense) {
      return 'Expense logged. Saving up is the superpower! 🛡️';
    } else {
      return 'Smooth tactical relocation between accounts! 🔄';
    }
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
      typeLabel = 'Income Received';
      typeIcon = Icons.north_east_rounded;
    } else if (type == TransactionType.expense) {
      accentColor = AppColors.expenseCoral;
      typeLabel = 'Expense Paid';
      typeIcon = Icons.south_west_rounded;
    } else {
      accentColor = AppColors.transferBlue;
      typeLabel = 'Account Transfer';
      typeIcon = Icons.swap_horiz_rounded;
    }

    final formattedAmount = CurrencyFormatter.format(
      widget.transaction.amount,
      currencyCode: widget.currencyCode,
      isMasked: widget.isMasked,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle & countdown indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      width: 50,
                      child: LinearProgressIndicator(
                        value: _dismissProgress,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.goldSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _dismissProgress > 0.3 ? AppColors.goldPrimary : AppColors.expenseCoral,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Speech Bubble
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(_mascotSpeech),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _mascotSpeech,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Interactive Mascot ("Coiny") with Coin Burst Particles
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Coin Blast Particles
                    CustomPaint(
                      size: const Size(180, 130),
                      painter: _CoinBlastPainter(particles: _coinParticles),
                    ),

                    // Interactive Drag & Poke mascot
                    GestureDetector(
                      onTap: _onPokeCoiny,
                      onPanUpdate: (details) {
                        setState(() {
                          _dragOffset = Offset(
                            (_dragOffset.dx + details.delta.dx).clamp(-40.0, 40.0),
                            (_dragOffset.dy + details.delta.dy).clamp(-30.0, 30.0),
                          );
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _dragOffset = Offset.zero;
                        });
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_idleController, _flipController]),
                        builder: (context, child) {
                          final idleBounce = sin(_idleController.value * pi) * 6;
                          final flipValue = _flipController.value * pi * 2;
                          final isFlipped = cos(flipValue) < 0;

                          return Transform.translate(
                            offset: Offset(_dragOffset.dx, _dragOffset.dy - idleBounce),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(flipValue)
                                ..rotateZ((_dragOffset.dx / 40.0) * 0.2),
                              child: CustomPaint(
                                size: const Size(100, 100),
                                painter: _LivingCoinPainter(
                                  idleProgress: _idleController.value,
                                  type: type,
                                  isDark: isDark,
                                  isFlipped: isFlipped,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Tap hint badge
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 12, color: AppColors.goldDark),
                            SizedBox(width: 4),
                            Text(
                              'Tap Coiny to spin coin! 🪙',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

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
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(typeIcon, size: 16, color: accentColor),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transaction.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 14),

              // Professional Action Buttons (Human-Designed Icons)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _onPokeCoiny,
                      icon: Icon(
                        type == TransactionType.income
                            ? Icons.monetization_on_outlined
                            : Icons.sentiment_satisfied_alt_rounded,
                        size: 18,
                      ),
                      label: Text(
                        type == TransactionType.income ? 'Coin Shower 🪙' : 'Cheer Up',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                      onPressed: _finishAndClose,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top-right Close Button ('X')
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _finishAndClose,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.goldSubtle.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotSpeed;
  double opacity;
  double age = 0.0;
  double maxLife;

  _CoinParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.opacity,
    required this.maxLife,
  });
}

class _CoinBlastPainter extends CustomPainter {
  final List<_CoinParticle> particles;

  _CoinBlastPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final p in particles) {
      if (p.opacity <= 0) continue;

      canvas.save();
      canvas.translate(cx + p.x, cy + p.y);
      canvas.rotate(p.rotation);

      final textSpan = TextSpan(
        text: '🪙',
        style: TextStyle(
          fontSize: p.size,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoinBlastPainter oldDelegate) => true;
}

class _LivingCoinPainter extends CustomPainter {
  final double idleProgress;
  final TransactionType type;
  final bool isDark;
  final bool isFlipped;

  _LivingCoinPainter({
    required this.idleProgress,
    required this.type,
    required this.isDark,
    required this.isFlipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = 44.0;
    final center = Offset(cx, cy);

    // 1. Drop Shadow
    canvas.drawCircle(
      center.translate(0, 6),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Bevelled 3D Champagne Gold Coin Body
    final rimPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.35),
        colors: [
          AppColors.goldLight,
          AppColors.goldPrimary,
          AppColors.goldDark,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);

    final facePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF4CE),
          AppColors.goldLight,
          AppColors.goldPrimary,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 5));

    canvas.drawCircle(center, radius - 5, facePaint);

    // Inner rim stamping ring
    canvas.drawCircle(
      center,
      radius - 6.5,
      Paint()
        ..color = AppColors.goldDark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3. Hands / Limbs waving
    final double armAngle = (type == TransactionType.income)
        ? -0.5 - (idleProgress * 0.3)
        : 0.3 + (idleProgress * 0.2);

    _drawArm(canvas, center.translate(-radius + 4, 8), isLeft: true, angle: armAngle);
    _drawArm(canvas, center.translate(radius - 4, 8), isLeft: false, angle: armAngle);

    // If flipped to back side during 3D coin spin, show emblem
    if (isFlipped) {
      final emblemPaint = Paint()
        ..color = AppColors.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(center, 18, emblemPaint);
      canvas.drawLine(center.translate(-8, 0), center.translate(8, 0), emblemPaint);
      canvas.drawLine(center.translate(0, -8), center.translate(0, 8), emblemPaint);
      return;
    }

    // 4. Facial Expressions
    if (type == TransactionType.income) {
      _drawIncomeFace(canvas, center);
      _drawCrown(canvas, center.translate(0, -radius - 2));
    } else if (type == TransactionType.expense) {
      _drawExpenseFace(canvas, center);
    } else {
      _drawTransferFace(canvas, center);
    }

    // 5. Specular curved glass shine highlight
    final shinePath = Path()
      ..moveTo(cx - 26, cy - radius + 10)
      ..quadraticBezierTo(cx + 20, cy - radius + 16, cx + 30, cy - 8)
      ..quadraticBezierTo(cx + 16, cy - radius + 28, cx - 26, cy - radius + 10);

    canvas.drawPath(
      shinePath,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawArm(Canvas canvas, Offset joint, {required bool isLeft, required double angle}) {
    final armPaint = Paint()
      ..color = AppColors.goldPrimary
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final double sign = isLeft ? -1 : 1;
    final endX = joint.dx + (cos(angle) * 16 * sign);
    final endY = joint.dy + (sin(angle) * 16);

    canvas.drawLine(joint, Offset(endX, endY), armPaint);
    canvas.drawCircle(Offset(endX, endY), 3.5, Paint()..color = AppColors.goldLight);
  }

  void _drawIncomeFace(Canvas canvas, Offset center) {
    _drawStarEye(canvas, center.translate(-15, -6), 7.0);
    _drawStarEye(canvas, center.translate(15, -6), 7.0);

    final cheekPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.7);
    canvas.drawCircle(center.translate(-20, 8), 5.0, cheekPaint);
    canvas.drawCircle(center.translate(20, 8), 5.0, cheekPaint);

    final mouthPath = Path()
      ..moveTo(center.dx - 13, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 24, center.dx + 13, center.dy + 8)
      ..close();

    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF5A1523));
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(center.translate(0, 16), 7.5, Paint()..color = const Color(0xFFFF6584));
    canvas.restore();
  }

  void _drawExpenseFace(Canvas canvas, Offset center) {
    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final highlight = Paint()..color = Colors.white;

    canvas.drawCircle(center.translate(-14, -4), 8.0, eyePaint);
    canvas.drawCircle(center.translate(-16, -7), 3.2, highlight);
    canvas.drawCircle(center.translate(-12, -2), 1.6, highlight);

    canvas.drawCircle(center.translate(14, -4), 8.0, eyePaint);
    canvas.drawCircle(center.translate(12, -7), 3.2, highlight);
    canvas.drawCircle(center.translate(16, -2), 1.6, highlight);

    final browPaint = Paint()
      ..color = const Color(0xFF5A3A00)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center.translate(-20, -15), center.translate(-9, -11), browPaint);
    canvas.drawLine(center.translate(20, -15), center.translate(9, -11), browPaint);

    final mouthPath = Path()
      ..moveTo(center.dx - 11, center.dy + 15)
      ..quadraticBezierTo(center.dx - 5, center.dy + 10, center.dx, center.dy + 12)
      ..quadraticBezierTo(center.dx + 5, center.dy + 10, center.dx + 11, center.dy + 15);

    canvas.drawPath(mouthPath, browPaint);
  }

  void _drawTransferFace(Canvas canvas, Offset center) {
    final glassPaint = Paint()..color = const Color(0xFF141722);
    final leftGlass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(-15, -5), width: 25, height: 16),
      const Radius.circular(5),
    );
    final rightGlass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(15, -5), width: 25, height: 16),
      const Radius.circular(5),
    );

    canvas.drawRRect(leftGlass, glassPaint);
    canvas.drawRRect(rightGlass, glassPaint);

    canvas.drawLine(
      center.translate(-3, -5),
      center.translate(3, -5),
      Paint()
        ..color = const Color(0xFF141722)
        ..strokeWidth = 2.5,
    );

    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    canvas.drawLine(center.translate(-23, -10), center.translate(-13, 0), glint);
    canvas.drawLine(center.translate(7, -10), center.translate(17, 0), glint);

    final smirkPath = Path()
      ..moveTo(center.dx - 8, center.dy + 13)
      ..quadraticBezierTo(center.dx + 4, center.dy + 15, center.dx + 11, center.dy + 9);

    canvas.drawPath(
      smirkPath,
      Paint()
        ..color = const Color(0xFF5A3A00)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
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

    canvas.drawPath(path, Paint()..color = const Color(0xFF4A2800));
    canvas.drawCircle(pos.translate(1, -1), r * 0.25, Paint()..color = Colors.white);
  }

  void _drawCrown(Canvas canvas, Offset pos) {
    final crownPath = Path()
      ..moveTo(pos.dx - 16, pos.dy)
      ..lineTo(pos.dx - 20, pos.dy - 14)
      ..lineTo(pos.dx - 8, pos.dy - 7)
      ..lineTo(pos.dx, pos.dy - 18)
      ..lineTo(pos.dx + 8, pos.dy - 7)
      ..lineTo(pos.dx + 20, pos.dy - 14)
      ..lineTo(pos.dx + 16, pos.dy)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.goldLight, AppColors.goldPrimary, AppColors.goldDark],
      ).createShader(Rect.fromCenter(center: pos, width: 40, height: 20));

    canvas.drawPath(crownPath, crownPaint);
    canvas.drawCircle(pos.translate(0, -18), 2.2, Paint()..color = const Color(0xFFFF2D55));
  }

  @override
  bool shouldRepaint(covariant _LivingCoinPainter oldDelegate) {
    return oldDelegate.idleProgress != idleProgress ||
        oldDelegate.type != type ||
        oldDelegate.isFlipped != isFlipped;
  }
}
