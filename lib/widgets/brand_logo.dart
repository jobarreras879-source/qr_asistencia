import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App logo with a pulsing animation used in Login and other screens.
class BrandLogo extends StatefulWidget {
  final double size;
  final IconData icon;

  const BrandLogo({
    super.key,
    this.size = 80,
    this.icon = Icons.qr_code_scanner_rounded,
  });

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.accentGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent
                    .withValues(alpha: 0.4 * _pulseAnim.value),
                blurRadius: 40 * _pulseAnim.value,
                spreadRadius: 4 * _pulseAnim.value,
              ),
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.1),
                blurRadius: 100,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        );
      },
    );
  }
}
