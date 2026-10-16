import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_record.dart';

/// Interactive Animated Coin Mascot ("Coiny") with 3D touch physics, coin flip, and particle effects
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
    with TickerProviderStateMixin {
  // Continuous idle breathing & bouncing controller
  late AnimationController _idleController;

  // 3D Coin Flip controller
  late AnimationController _flipController;

  // Elastic drag offset
  Offset _dragOffset = Offset.zero;

  // Continuous particle simulator
  final List<_MascotParticle> _particles = [];
  Timer? _particleTimer;
  final Random _random = Random();

  Timer? _autoDismissTimer;
  double _dismissProgress = 1.0;
  Timer? _progressTimer;
  int _pokeCount = 0;
  late String _mascotSpeech;

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

    // Initial burst of particles
    _spawnParticles(count: 24);

    // Continuous particle generation at 30fps
    _particleTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (mounted) {
        _updateParticles();
      }
    });

    // Auto-dismiss countdown (3.8 seconds total so user can play with Coiny)
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
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismissed?.call();
      }
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

  void _spawnParticles({int count = 10}) {
    final type = widget.transaction.type;
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 30.0 + _random.nextDouble() * 120.0;

      Color pColor;
      if (type == TransactionType.income) {
        pColor = i.isEven ? AppColors.goldPrimary : AppColors.goldLight;
      } else if (type == TransactionType.expense) {
        pColor = const Color(0xFF4FC3F7);
      } else {
        pColor = i.isEven ? AppColors.transferBlue : AppColors.goldLight;
      }

      _particles.add(
        _MascotParticle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - (type == TransactionType.income ? 60 : 0),
          color: pColor,
          size: 3.5 + _random.nextDouble() * 5.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8.0,
          maxLife: 0.8 + _random.nextDouble() * 0.8,
        ),
      );
    }
  }

  void _updateParticles() {
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.age += 0.06;
        p.x += p.vx * 0.06;
        p.y += p.vy * 0.06;
        p.rotation += p.rotationSpeed * 0.06;

        // Gravity
        if (widget.transaction.type == TransactionType.income) {
          p.vy += 80 * 0.06;
        } else if (widget.transaction.type == TransactionType.expense) {
          p.vy += 120 * 0.06;
        }

        if (p.age >= p.maxLife) {
          _particles.removeAt(i);
        }
      }

      // Keep spawning continuous flow
      if (_particles.length < 20) {
        _spawnParticles(count: 3);
      }
    });
  }

  void _onPokeCoiny() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _flipController.forward(from: 0.0);
    _spawnParticles(count: 16);

    setState(() {
      _pokeCount++;
      if (widget.transaction.type == TransactionType.income) {
        final phrases = [
          'Wheee! Coin shower! 🌟🪙',
          'Stacking up the gold! 👑',
          'You clicked me! More wealth incoming! 🚀',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else if (widget.transaction.type == TransactionType.expense) {
        final phrases = [
          'Oof! Don\'t poke, I\'m mourning the budget! 🥺',
          'Shedding little gold tears! 😭💸',
          'Watch the wallet! Protect the vault! 🛡️',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else {
        final phrases = [
          'Vault swap confirmed! 🕶️⚡',
          'Hyperdrive transfer complete! 🌀',
          'Smooth positioning! 😎',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      }
    });
  }

  String _getRandomPhrase(TransactionType type) {
    if (type == TransactionType.income) {
      return 'Cha-ching! Inflow secured! We\'re growing! 🤑✨';
    } else if (type == TransactionType.expense) {
      return 'Ouch! Expense logged. Spend mindfully! 💸🥺';
    } else {
      return 'Smooth tactical relocation between vaults! 🔄🏦';
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
      typeLabel = 'Transfer Relocated';
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auto-dismiss countdown line
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _dismissProgress,
              minHeight: 3.5,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 14),

          // Speech Bubble
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
          const SizedBox(height: 10),

          // Interactive 3D Physics Character Area
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Live Particle Layer
                CustomPaint(
                  size: const Size(220, 170),
                  painter: _ParticleCanvasPainter(particles: _particles),
                ),

                // Interactive Draggable / Flippable Coin Character
                GestureDetector(
                  onTap: _onPokeCoiny,
                  onPanUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta * 0.6;
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _dragOffset = Offset.zero;
                    });
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_idleController, _flipController]),
                    builder: (context, _) {
                      // Elastic spring bounce when returning from drag
                      final idleBounce = sin(_idleController.value * pi) * 6.0;
                      final flipVal = _flipController.value;

                      return Transform.translate(
                        offset: Offset(_dragOffset.dx, _dragOffset.dy - idleBounce),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002) // 3D Perspective
                            ..rotateY(flipVal * 2 * pi) // Full 360 flip on poke
                            ..rotateZ((_dragOffset.dx * 0.008).clamp(-0.25, 0.25)),
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: _LivingCoinPainter(
                                idleProgress: _idleController.value,
                                type: type,
                                isDark: isDark,
                                isFlipped: flipVal > 0.25 && flipVal < 0.75,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Tap & Drag hint badge
                Positioned(
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white.withValues(alpha: 0.9),
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
                          'Tap or drag Coiny to interact',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.goldDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Transaction Pill
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
          const SizedBox(height: 16),

          // Interactive Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _onPokeCoiny,
                  icon: const Icon(Icons.celebration_rounded, size: 16),
                  label: Text(
                    type == TransactionType.income ? 'Make It Rain 🪙' : 'Cheer Up 🌟',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDismissed?.call();
                  },
                  child: const Text('Awesome! ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MascotParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  double age = 0.0;
  double maxLife;

  _MascotParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.maxLife,
  });
}

class _ParticleCanvasPainter extends CustomPainter {
  final List<_MascotParticle> particles;

  _ParticleCanvasPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final p in particles) {
      final alpha = (1.0 - (p.age / p.maxLife)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(cx + p.x, cy + p.y);
      canvas.rotate(p.rotation);

      // Render as miniature gold coin or star
      final r = Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.7);
      canvas.drawOval(r, paint);
      canvas.drawOval(
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleCanvasPainter oldDelegate) => true;
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
    final double radius = 46.0;
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

    // Stamping inner rim ring
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
        ? -0.5 - (idleProgress * 0.3) // hands up celebrating
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
      ..moveTo(cx - 28, cy - radius + 10)
      ..quadraticBezierTo(cx + 22, cy - radius + 16, cx + 32, cy - 8)
      ..quadraticBezierTo(cx + 18, cy - radius + 28, cx - 28, cy - radius + 10);

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
    // Star sparkle eyes
    _drawStarEye(canvas, center.translate(-15, -6), 7.0);
    _drawStarEye(canvas, center.translate(15, -6), 7.0);

    // Blushing cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.7);
    canvas.drawCircle(center.translate(-20, 8), 5.0, cheekPaint);
    canvas.drawCircle(center.translate(20, 8), 5.0, cheekPaint);

    // Wide open happy grin with tongue
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
    // Big teary anime eyes
    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final highlight = Paint()..color = Colors.white;

    canvas.drawCircle(center.translate(-14, -4), 8.0, eyePaint);
    canvas.drawCircle(center.translate(-16, -7), 3.2, highlight);
    canvas.drawCircle(center.translate(-12, -2), 1.6, highlight);

    canvas.drawCircle(center.translate(14, -4), 8.0, eyePaint);
    canvas.drawCircle(center.translate(12, -7), 3.2, highlight);
    canvas.drawCircle(center.translate(16, -2), 1.6, highlight);

    // Worried downturned eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF5A3A00)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center.translate(-20, -15), center.translate(-9, -11), browPaint);
    canvas.drawLine(center.translate(20, -15), center.translate(9, -11), browPaint);

    // Trembling mouth
    final mouthPath = Path()
      ..moveTo(center.dx - 11, center.dy + 15)
      ..quadraticBezierTo(center.dx - 5, center.dy + 10, center.dx, center.dy + 12)
      ..quadraticBezierTo(center.dx + 5, center.dy + 10, center.dx + 11, center.dy + 15);

    canvas.drawPath(mouthPath, browPaint);
  }

  void _drawTransferFace(Canvas canvas, Offset center) {
    // Cool dark sunglasses
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

    // Frame Bridge
    canvas.drawLine(
      center.translate(-3, -5),
      center.translate(3, -5),
      Paint()
        ..color = const Color(0xFF141722)
        ..strokeWidth = 2.5,
    );

    // Diagonal Glint
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    canvas.drawLine(center.translate(-23, -10), center.translate(-13, 0), glint);
    canvas.drawLine(center.translate(7, -10), center.translate(17, 0), glint);

    // Confident smirk
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
