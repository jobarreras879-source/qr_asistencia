import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class SuccessScreen extends StatefulWidget {
  final String message;
  final String usuario;
  final String rol;

  const SuccessScreen({
    super.key,
    required this.message,
    required this.usuario,
    required this.rol,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _particleController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _particleController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              ...List.generate(10, (i) => _buildParticle(i)),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedBuilder(
                  animation: _checkController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Animated check circle
                        Opacity(
                          opacity: _checkOpacity.value,
                          child: Transform.scale(
                            scale: _checkScale.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        Transform.translate(
                          offset: Offset(0, _contentSlide.value),
                          child: Opacity(
                            opacity: (1 - _contentSlide.value / 30).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Registro completado',
                                  style: GoogleFonts.ibmPlexSerif(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),

                                // Details card
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.glassDecoration,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .assignment_turned_in_rounded,
                                              color: AppTheme.success,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.message,
                                              style: GoogleFonts.ibmPlexSans(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(
                                        color: AppTheme.border,
                                        height: 1,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.photo_camera_rounded,
                                            color: AppTheme.success,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Foto guardada correctamente',
                                            style: GoogleFonts.ibmPlexSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Buttons
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: AppTheme.accentGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accent.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomeScreen(
                                            usuario: widget.usuario,
                                            rol: widget.rol,
                                          ),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Registrar otra asistencia',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index * 42);
    final startX = random.nextDouble() * MediaQuery.of(context).size.width;
    final startY =
        MediaQuery.of(context).size.height * 0.4 +
        random.nextDouble() * 100 -
        50;
    final endY = -50.0;
    final endX = startX + (random.nextDouble() - 0.5) * 200;
    final size = 4.0 + random.nextDouble() * 8;
    final color = [
      AppTheme.success,
      AppTheme.accent,
      AppTheme.accent2,
      const Color(0xFF7C3AED),
      Colors.white,
    ][index % 5];

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final t = (_particleController.value - index * 0.02).clamp(0.0, 1.0);
        final curve = Curves.easeOutQuad.transform(t);
        final opacity = (1 - curve).clamp(0.0, 1.0);

        return Positioned(
          left: startX + (endX - startX) * curve,
          top: startY + (endY - startY) * curve,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: curve * math.pi * 2 * (random.nextBool() ? 1 : -1),
              child: Container(
                width: size,
                height: size * (random.nextBool() ? 1 : 0.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    random.nextBool() ? size : 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
