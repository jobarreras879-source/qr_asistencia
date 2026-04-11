import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginHero extends StatelessWidget {
  static const _heroColor = Color(0xFF001A6B);
  static const _heroColorDark = Color(0xFF031C74);
  static const _heroAccent = Color(0xFF3FC6FF);
  static const _heroTextMuted = Color(0xFFB8C7FF);

  final double height;
  final bool compact;

  const LoginHero({super.key, required this.height, required this.compact});

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = compact
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = compact ? TextAlign.center : TextAlign.left;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 34 : 40),
          gradient: const LinearGradient(
            colors: [_heroColor, _heroColorDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _heroColor.withValues(alpha: 0.18),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 34 : 40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -48,
                right: -42,
                child: Container(
                  width: compact ? 156 : 220,
                  height: compact ? 156 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _heroAccent.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                left: -32,
                bottom: compact ? 82 : 28,
                child: Container(
                  width: compact ? 110 : 158,
                  height: compact ? 110 : 158,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _HeroGridPainter()),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: compact ? 0.14 : 0.24),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 24 : 38,
                  compact ? 28 : 38,
                  compact ? 24 : 38,
                  compact ? 26 : 32,
                ),
                child: Column(
                  crossAxisAlignment: crossAxisAlignment,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroPill(
                      label: compact ? 'Acceso seguro' : 'Plataforma operativa',
                    ),
                    SizedBox(height: compact ? 18 : 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/LogoAVS.png',
                        height: compact ? 52 : 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    Text(
                      'AVS Ingeniería',
                      textAlign: textAlign,
                      style: GoogleFonts.manrope(
                        fontSize: compact ? 28 : 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 320 : 520,
                      ),
                      child: Text(
                        compact
                            ? 'Registro de asistencia con acceso seguro y control operativo.'
                            : 'Control de asistencia con acceso seguro, historial operativo y sincronización administrativa.',
                        textAlign: textAlign,
                        style: GoogleFonts.inter(
                          fontSize: compact ? 15 : 17,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                          color: _heroTextMuted,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    Wrap(
                      alignment: compact
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _HeroTag(label: 'Marcación QR'),
                        _HeroTag(label: 'Historial diario'),
                        _HeroTag(label: 'Google Sheets'),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flujo preparado para operación interna',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Autenticación, control de jornada y sincronización con herramientas administrativas en una sola experiencia.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.55,
                                color: _heroTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;

  const _HeroTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.96),
        ),
      ),
    );
  }
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    const grid = 36.0;
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
