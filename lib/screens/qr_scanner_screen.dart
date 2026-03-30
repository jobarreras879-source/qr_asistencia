import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/qr_scanner_overlay.dart';
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

      final msgOrError = await AttendanceService.registrarAsistencia(
        code,
        widget.proyectoInfo,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
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

          // Overlay UI & Instruction
          QRScannerOverlay(
            scanAreaSize: scanAreaSize,
            scanLineAnimation: _scanLineController,
            tipo: widget.tipo,
            proyectoInfo: widget.proyectoInfo,
            onBack: () => Navigator.pop(context),
          ),

          // Processing state
          if (_isProcessing) const ProcessingOverlay(message: 'Registrando...'),
        ],
      ),
    );
  }
}
