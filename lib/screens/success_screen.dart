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
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
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
        curve: const Interval(0, 0.28, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<double>(begin: 26.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _checkController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _checkController,
            builder: (context, child) {
              return Column(
                children: [
                  const Spacer(flex: 5),
                  Opacity(
                    opacity: _checkOpacity.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 62,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Transform.translate(
                    offset: Offset(0, _contentSlide.value),
                    child: Opacity(
                      opacity: (1 - _contentSlide.value / 26).clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          Text(
                            '¡Registro Exitoso!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'La asistencia ha sido registrada\ncorrectamente',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Foto guardada correctamente',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
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
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'Registrar otra asistencia',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                elevation: 0,
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
                  const Spacer(flex: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
