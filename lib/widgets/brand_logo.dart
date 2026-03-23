import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App logo with a restrained, more formal presentation.
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
            borderRadius: BorderRadius.circular(widget.size * 0.24),
            gradient: AppTheme.headerGradient,
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent
                    .withValues(alpha: 0.16 * _pulseAnim.value),
                blurRadius: 24 * _pulseAnim.value,
                spreadRadius: 1.5 * _pulseAnim.value,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: widget.size * 0.18,
                child: Container(
                  width: widget.size * 0.42,
                  height: 2,
                  color: AppTheme.accent2.withValues(alpha: 0.9),
                ),
              ),
              Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.44,
              ),
            ],
          ),
        );
      },
    );
  }
}
