import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_record.dart';

/// Full-Screen Arcade Coin Blast & Mascot Reaction Dialog
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
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CoinCelebration',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => CoinCharacterReactionModal(
        transaction: transaction,
        currencyCode: currencyCode,
        isMasked: isMasked,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<CoinCharacterReactionModal> createState() => _CoinCharacterReactionModalState();
}

class _CoinCharacterReactionModalState extends State<CoinCharacterReactionModal>
    with TickerProviderStateMixin {
  // Idle breathing animation
  late AnimationController _idleController;
  // Mascot 3D flip animation
  late AnimationController _flipController;
  // Vacuum absorption animation controller
  late AnimationController _vacuumController;

  // Mascot drag offset
  Offset _dragOffset = Offset.zero;

  // Full-screen arcade coin blast physics list
  final List<_ArcadeCoin> _arcadeCoins = [];
  Timer? _physicsTimer;
  final Random _random = Random();

  Timer? _autoDismissTimer;
  double _dismissProgress = 1.0;
  Timer? _progressTimer;
  int _pokeCount = 0;
  late String _mascotSpeech;
  bool _isAbsorbing = false;
  Offset _absorptionTarget = const Offset(200, 120);

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

    _vacuumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _mascotSpeech = _getRandomPhrase(widget.transaction.type);

    // Initial Arcade Coin Blast! (40+ coins exploding outward)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        _absorptionTarget = Offset(size.width / 2, size.height * 0.16);
        _launchArcadeCoinBlast(count: 38);
      }
    });

    // 60fps physics simulation ticker
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) {
        _tickPhysics();
      }
    });

    // Auto-dismiss countdown (4.5s so user can play with coin blast)
    const totalMs = 4500;
    const intervalMs = 50;
    int elapsed = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (_isAbsorbing) return;
      elapsed += intervalMs;
      if (mounted) {
        setState(() {
          _dismissProgress = (1.0 - (elapsed / totalMs)).clamp(0.0, 1.0);
        });
      }
    });

    _autoDismissTimer = Timer(const Duration(milliseconds: totalMs), () {
      if (mounted && !_isAbsorbing) {
        _startVacuumAbsorption();
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
    _vacuumController.dispose();
    _physicsTimer?.cancel();
    _autoDismissTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _launchArcadeCoinBlast({int count = 30}) {
    final size = MediaQuery.of(context).size;
    final startX = size.width / 2;
    final startY = size.height * 0.52; // originate from mascot

    final type = widget.transaction.type;

    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * (pi * 0.85);
      final speed = 250.0 + _random.nextDouble() * 450.0;

      String emoji = '🪙';
      if (type == TransactionType.income) {
        final options = ['🪙', '🪙', '🪙', '✨', '🌟', '💰'];
        emoji = options[_random.nextInt(options.length)];
      } else if (type == TransactionType.expense) {
        final options = ['🪙', '💧', '💸', '🥺', '⚡'];
        emoji = options[_random.nextInt(options.length)];
      } else {
        final options = ['🪙', '🔄', '⚡', '💫', '✨'];
        emoji = options[_random.nextInt(options.length)];
      }

      _arcadeCoins.add(
        _ArcadeCoin(
          x: startX + (_random.nextDouble() - 0.5) * 40,
          y: startY + (_random.nextDouble() - 0.5) * 40,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          emoji: emoji,
          size: 18.0 + _random.nextDouble() * 18.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotSpeed: (_random.nextDouble() - 0.5) * 9.0,
          scale: 0.2,
          targetScale: 0.8 + _random.nextDouble() * 0.45,
          opacity: 1.0,
        ),
      );
    }
  }

  void _tickPhysics() {
    final size = MediaQuery.of(context).size;
    final dt = 0.016;

    setState(() {
      for (int i = _arcadeCoins.length - 1; i >= 0; i--) {
        final coin = _arcadeCoins[i];

        if (_isAbsorbing) {
          // Vacuum Absorption: curve towards absorption target
          final dx = _absorptionTarget.dx - coin.x;
          final dy = _absorptionTarget.dy - coin.y;
          final dist = sqrt(dx * dx + dy * dy);

          if (dist < 28) {
            // Absorbed into vault!
            _arcadeCoins.removeAt(i);
            continue;
          }

          final pullStrength = 1800.0;
          coin.vx += (dx / dist) * pullStrength * dt;
          coin.vy += (dy / dist) * pullStrength * dt;
          coin.x += coin.vx * dt;
          coin.y += coin.vy * dt;
          coin.rotation += coin.rotSpeed * dt * 3;
          coin.scale = (coin.scale - 0.035).clamp(0.05, 1.5);
          coin.opacity = (coin.opacity - 0.02).clamp(0.0, 1.0);
        } else {
          // Standard Arcade physics with gravity and bounce
          coin.vy += 650.0 * dt; // gravity
          coin.x += coin.vx * dt;
          coin.y += coin.vy * dt;
          coin.rotation += coin.rotSpeed * dt;

          // Scale pop-in
          if (coin.scale < coin.targetScale) {
            coin.scale = (coin.scale + dt * 4.5).clamp(0.0, coin.targetScale);
          }

          // Screen boundaries bounce
          if (coin.x < 15) {
            coin.x = 15;
            coin.vx = -coin.vx * 0.65;
          } else if (coin.x > size.width - 25) {
            coin.x = size.width - 25;
            coin.vx = -coin.vx * 0.65;
          }

          // Floor bounce
          if (coin.y > size.height - 35) {
            coin.y = size.height - 35;
            coin.vy = -coin.vy * 0.55;
            coin.vx = coin.vx * 0.85; // friction
          }
        }
      }

      // If absorbing finished and all coins absorbed, close modal
      if (_isAbsorbing && _arcadeCoins.isEmpty) {
        _finishAndClose();
      }
    });
  }

  void _startVacuumAbsorption() {
    if (_isAbsorbing) return;
    _isAbsorbing = true;
    _autoDismissTimer?.cancel();
    _progressTimer?.cancel();

    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    setState(() {
      _mascotSpeech = 'Absorbing wealth into the vault! 🚀✨';
    });
  }

  void _finishAndClose() {
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
    _launchArcadeCoinBlast(count: 22);

    setState(() {
      _pokeCount++;
      if (widget.transaction.type == TransactionType.income) {
        final phrases = [
          'Wheee! Coin shower! 🌟🪙',
          'Stacking up the gold! 👑',
          'You clicked me! More wealth incoming! 🚀',
          'Arcade frenzy activated! 🪙⚡',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else if (widget.transaction.type == TransactionType.expense) {
        final phrases = [
          'Oof! Don\'t poke, I\'m mourning the budget! 🥺',
          'Shedding little gold tears! 😭💸',
          'Watch the wallet! Protect the vault! 🛡️',
          'Saving up is the true superpower! 💪',
        ];
        _mascotSpeech = phrases[_pokeCount % phrases.length];
      } else {
        final phrases = [
          'Vault swap confirmed! 🕶️⚡',
          'Hyperdrive transfer complete! 🌀',
          'Smooth tactical positioning! 😎',
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
      typeLabel = 'Account Transfer';
      typeIcon = Icons.swap_horiz_rounded;
    }

    final formattedAmount = CurrencyFormatter.format(
      widget.transaction.amount,
      currencyCode: widget.currencyCode,
      isMasked: widget.isMasked,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Tap dismiss/absorb layer
          GestureDetector(
            onTap: _startVacuumAbsorption,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // Arcade Coin Blast Flying Particles
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ArcadeCoinBlastPainter(coins: _arcadeCoins),
            ),
          ),

          // Top Vacuum Target Glow Pill
          Positioned(
            top: 50,
            left: 24,
            right: 24,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isAbsorbing ? 1.0 : 0.85,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurfaceElevated : Colors.white)
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isAbsorbing ? AppColors.goldPrimary : AppColors.cardBorder,
                      width: _isAbsorbing ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withValues(alpha: _isAbsorbing ? 0.4 : 0.15),
                        blurRadius: _isAbsorbing ? 18 : 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        _isAbsorbing ? 'Collecting Coins...' : 'Tap anywhere to Collect ✨',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Mascot and Details Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dismiss progress bar indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      width: 54,
                      child: LinearProgressIndicator(
                        value: _dismissProgress,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.goldSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _dismissProgress > 0.3 ? AppColors.goldPrimary : AppColors.expenseCoral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mascot Speech Bubble
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

                  // Interactive Mascot ("Coiny")
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Interactive Drag & Tap mascot
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
                              final idleBounce = sin(_idleController.value * pi) * 7;
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
                                    size: const Size(110, 110),
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

                        // Interactive hint badge
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
                                  'Tap Coiny to blast coins! 🪙',
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

                  // Transaction Summary Card
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

                  // Action Buttons
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
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 1,
                          ),
                          onPressed: _startVacuumAbsorption,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text(
                            'Collect Coins ✨',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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
    );
  }
}

class _ArcadeCoin {
  double x;
  double y;
  double vx;
  double vy;
  String emoji;
  double size;
  double rotation;
  double rotSpeed;
  double scale;
  double targetScale;
  double opacity;

  _ArcadeCoin({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.emoji,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.scale,
    required this.targetScale,
    required this.opacity,
  });
}

class _ArcadeCoinBlastPainter extends CustomPainter {
  final List<_ArcadeCoin> coins;

  _ArcadeCoinBlastPainter({required this.coins});

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      if (coin.opacity <= 0 || coin.scale <= 0) continue;

      canvas.save();
      canvas.translate(coin.x, coin.y);
      canvas.scale(coin.scale);
      canvas.rotate(coin.rotation);

      final textSpan = TextSpan(
        text: coin.emoji,
        style: TextStyle(
          fontSize: coin.size,
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
  bool shouldRepaint(covariant _ArcadeCoinBlastPainter oldDelegate) => true;
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

    // 3. Limbs waving
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
