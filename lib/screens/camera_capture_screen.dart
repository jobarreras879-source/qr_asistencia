import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
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

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isUploading = false;
  bool _flashEffect = false;

  late AnimationController _uploadAnimController;
  late Animation<double> _uploadAnim;

  @override
  void initState() {
    super.initState();
    _uploadAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _uploadAnim = Tween<double>(begin: 0, end: 1).animate(_uploadAnimController);

    _initCamera();
  }

  @override
  void dispose() {
    _uploadAnimController.dispose();
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

    // Verificar primero si Drive está configurado
    final folderId = await GoogleDriveService.getDriveFolderId();
    if (folderId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.add_to_drive_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Error: Carpeta de Google Drive no configurada. Pide a un administrador que configure Drive.')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Flash effect
    setState(() => _flashEffect = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _flashEffect = false);

    setState(() => _isUploading = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final fullBase64 = 'data:image/jpeg;base64,$base64String';

      // SUBIDA DIRECTA A GOOGLE DRIVE
      final success = await GoogleDriveService.uploadPhoto(
        folderId, 
        fullBase64, 
        widget.nombreBase
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => SuccessScreen(
              message: widget.resultMessage,
              usuario: widget.usuario,
              rol: widget.rol,
            ),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
              );
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Expanded(child: Text('No se pudo tomar o subir la fotografía. Intenta de nuevo.')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Iniciando cámara...',
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCamera(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Flash effect overlay
          if (_flashEffect)
            Positioned.fill(
              child: Container(color: Colors.white),
            ),

          // Upload overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
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
                        AnimatedBuilder(
                          animation: _uploadAnim,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 56,
                                  width: 56,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accent,
                                    strokeWidth: 3,
                                    value: null,
                                  ),
                                ),
                                const Icon(Icons.cloud_upload_rounded,
                                    color: AppTheme.accent, size: 24),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Subiendo imagen...',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Por favor espera',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top bar
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : () => Navigator.pop(context),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomar Fotografía',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Evidencia de asistencia',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          if (!_isUploading)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel
                  _buildCircleButton(
                    icon: Icons.close_rounded,
                    size: 52,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Capture
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
                            color: AppTheme.accent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flip camera
                  _buildCircleButton(
                    icon: Icons.flip_camera_android_rounded,
                    size: 52,
                    onTap: _switchCamera,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return _buildLoadingState();
    }

    return _buildActiveCamera(context);
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
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
