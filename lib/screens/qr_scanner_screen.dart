import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/processing_overlay.dart';
import 'camera_capture_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String usuario;
  final String rol;
  final String projectNumber;
  final String projectName;
  final String projectClient;
  final String tipo;

  const QRScannerScreen({
    super.key,
    required this.usuario,
    required this.rol,
    required this.projectNumber,
    required this.projectName,
    required this.projectClient,
    required this.tipo,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController cameraController = MobileScannerController();

  String get _projectHeader {
    final projectNumber = widget.projectNumber.trim();
    final projectName = widget.projectName.trim();
    if (projectName.isEmpty || projectName == 'Sin nombre') {
      return 'Proyecto #$projectNumber';
    }
    return 'Proyecto #$projectNumber - $projectName';
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final code = barcodes.first.rawValue!;
    setState(() => _isProcessing = true);
    await cameraController.stop();

    final msgOrError = await AttendanceService.registrarAsistencia(
      code,
      widget.projectNumber,
      widget.usuario,
      widget.tipo,
    );

    if (!mounted) return;

    if (msgOrError != null && msgOrError.startsWith('✅')) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              CameraCaptureScreen(
                nombreBase: code.substring(
                  0,
                  code.length < 13 ? code.length : 13,
                ),
                usuario: widget.usuario,
                rol: widget.rol,
                resultMessage: msgOrError,
              ),
          transitionsBuilder: (context, anim, secondaryAnimation, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Error: ${msgOrError ?? 'No se pudo registrar'}'),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scannerSize = math.min(screenWidth - 96, 256.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCameraPreview()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildScannerGuide(scannerSize),
                  const Spacer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isProcessing) const ProcessingOverlay(message: 'Registrando...'),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return MobileScanner(
      controller: cameraController,
      onDetect: _handleBarcode,
      placeholderBuilder: (context) => const SizedBox.expand(),
      errorBuilder: (context, error) {
        return Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: const Icon(
            Icons.no_photography_outlined,
            color: Colors.white70,
            size: 54,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isProcessing ? null : () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escanear Código QR',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _projectHeader,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.scannerMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 7),
              const SizedBox(width: 6),
              Text(
                'Asistencia',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerGuide(double size) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.scannerBorder, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.scannerBorder.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.scannerBorder,
                  strokeWidth: 2.6,
                ),
              )
            : null,
      ),
    );
  }
}
