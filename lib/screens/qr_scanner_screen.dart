import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'camera_capture_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String usuario;
  final String rol;
  final String proyectoInfo;
  final String tipo;

  const QRScannerScreen({
    super.key,
    required this.usuario,
    required this.rol,
    required this.proyectoInfo,
    required this.tipo,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);

      cameraController.stop();

      // Show processing overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registrando...',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final msgOrError = await ApiService.registrarAsistencia(
        code,
        widget.proyectoInfo,
        widget.usuario,
        widget.tipo,
      );

      if (!mounted) return;
      Navigator.pop(context); // close dialog

      if (msgOrError != null && msgOrError.startsWith('✅')) {
        // Navigate to camera capture
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => CameraCaptureScreen(
              nombreBase:
                  code.substring(0, code.length < 13 ? code.length : 13),
              usuario: widget.usuario,
              rol: widget.rol,
              resultMessage: msgOrError,
            ),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Error: $msgOrError')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context); // go back to home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _handleBarcode,
            ),
          ),

          // Dark overlay with transparent center
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(scanAreaSize: scanAreaSize),
            ),
          ),

          // Scanning line animation
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (context, child) {
              final centerY = MediaQuery.of(context).size.height / 2;
              final top = centerY - scanAreaSize / 2;
              final lineY =
                  top + scanAreaSize * _scanLineController.value;

              return Positioned(
                top: lineY,
                left: (MediaQuery.of(context).size.width - scanAreaSize) / 2 +
                    8,
                child: Container(
                  width: scanAreaSize - 16,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.accent.withOpacity(0.8),
                        AppTheme.accent,
                        AppTheme.accent.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Corner markers
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: CustomPaint(
                  painter: _CornerPainter(),
                ),
              ),
            ),
          ),

          // Top info bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escaneando QR',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (widget.tipo == 'Proyectos'
                                        ? AppTheme.accent
                                        : AppTheme.accent2)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.tipo,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.tipo == 'Proyecto'
                                      ? AppTheme.accent
                                      : AppTheme.accent2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Proyecto ${widget.proyectoInfo}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded,
                          color: AppTheme.accent, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Apunta la cámara al código QR',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark overlay with transparent center window
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  _ScanOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw overlay around the scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: scanAreaSize,
            height: scanAreaSize),
        const Radius.circular(16),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated corner markers for the scan area
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(const Offset(radius, 0),
            radius: const Radius.circular(radius))
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius),
            radius: const Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height),
            radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius),
            radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
