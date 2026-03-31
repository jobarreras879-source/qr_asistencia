import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/processing_overlay.dart';
import 'success_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String nombreBase;
  final String usuario;
  final String rol;
  final String resultMessage;

  const CameraCaptureScreen({
    super.key,
    required this.nombreBase,
    required this.usuario,
    required this.rol,
    required this.resultMessage,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isUploading = false;
  bool _flashEffect = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _startCamera(_cameras.first);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() => _isCameraInitialized = false);
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_currentCameraIndex]);
  }

  Future<void> _takePictureAndUpload() async {
    if (!_controller!.value.isInitialized || _isUploading) return;

    final folderId = await GoogleDriveService.getDriveFolderId();
    if (folderId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.add_to_drive_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Error: Carpeta de Google Drive no configurada. Pide a un administrador que configure Drive.',
                ),
              ),
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
      return;
    }

    setState(() => _flashEffect = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _flashEffect = false);

    setState(() => _isUploading = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final fullBase64 = 'data:image/jpeg;base64,$base64String';

      final success = await GoogleDriveService.uploadPhoto(
        folderId,
        fullBase64,
        widget.nombreBase,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                SuccessScreen(
                  message: widget.resultMessage,
                  usuario: widget.usuario,
                  rol: widget.rol,
                ),
            transitionsBuilder: (context, anim, secondaryAnimation, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Error al subir la fotografía'),
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
        setState(() => _isUploading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se pudo tomar o subir la fotografía. Intenta de nuevo.',
                ),
              ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Iniciando cámara...',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraPreview()),
          if (_flashEffect)
            Positioned.fill(child: Container(color: Colors.white)),
          if (_isUploading)
            const ProcessingOverlay(
              message: 'Subiendo imagen...',
              subMessage: 'Por favor espera',
              icon: Icons.cloud_upload_rounded,
            ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          if (!_isUploading)
            Positioned(bottom: 50, left: 0, right: 0, child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
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
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tomar Fotografía',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Evidencia de asistencia',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleButton(
          icon: Icons.close_rounded,
          size: 52,
          onTap: () => Navigator.pop(context),
        ),
        GestureDetector(
          onTap: _takePictureAndUpload,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                height: 64,
                width: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        _buildCircleButton(
          icon: Icons.flip_camera_android_rounded,
          size: 52,
          onTap: _switchCamera,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
