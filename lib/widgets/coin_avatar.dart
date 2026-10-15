import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CoinAvatar extends StatelessWidget {
  final double size;
  final bool showRing;

  const CoinAvatar({
    super.key,
    this.size = 44,
    this.showRing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEADBBE),
            AppColors.goldPrimary,
            Color(0xFF9E7B35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withAlpha(70),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: showRing
            ? Border.all(
                color: Colors.white.withAlpha(200),
                width: size * 0.05,
              )
            : null,
      ),
      child: Center(
        child: Container(
          width: size * 0.76,
          height: size * 0.76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goldLight.withAlpha(150),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'MT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.34,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
