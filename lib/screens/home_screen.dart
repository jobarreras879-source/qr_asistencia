import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_header.dart';
import '../widgets/project_selector_card.dart';
import '../widgets/quick_actions_grid.dart';
import 'qr_scanner_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String usuario;
  final String rol;

  const HomeScreen({super.key, required this.usuario, required this.rol});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _proyectos = [];
  String? _proyectoIdSeleccionado;
  late String _usuarioActual;
  late String _rolActual;

  late AnimationController _fadeController;
  late AnimationController _scanPulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scanPulseAnim;

  @override
  void initState() {
    super.initState();
    _usuarioActual = widget.usuario;
    _rolActual = widget.rol;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanPulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanPulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _refreshSessionInfo();
    _fetchProyectos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scanPulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchProyectos() async {
    setState(() => _isLoading = true);
    final proys = await ProjectService.getProyectos();
    if (!mounted) return;
    setState(() {
      _proyectos = proys;
      _isLoading = false;
    });
  }

  Future<void> _refreshSessionInfo() async {
    final session = await AuthService.restoreSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    setState(() {
      _usuarioActual = session['usuario']!;
      _rolActual = session['rol']!;
    });
  }

  void _iniciarRegistro() {
    if (_proyectoIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Selecciona un Proyecto'),
            ],
          ),
          backgroundColor: AppTheme.accent2,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => QRScannerScreen(
          usuario: _usuarioActual,
          rol: _rolActual,
          proyectoInfo: _proyectoIdSeleccionado!,
          tipo: 'Proyecto',
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(usuario: _usuarioActual),
                  const SizedBox(height: 28),
                  ProjectSelectorCard(
                    isLoading: _isLoading,
                    proyectos: _proyectos,
                    proyectoIdSeleccionado: _proyectoIdSeleccionado,
                    onChanged: (val) =>
                        setState(() => _proyectoIdSeleccionado = val),
                  ),
                  const SizedBox(height: 24),
                  QuickActionsGrid(
                    rol: _rolActual,
                    onLogout: _logout,
                    onRefreshProyectos: _fetchProyectos,
                  ),
                  const Spacer(),
                  _buildScanButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    final bool isReady = _proyectoIdSeleccionado != null;

    return AnimatedBuilder(
      animation: _scanPulseAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isReady ? AppTheme.accentGradient : null,
            color: isReady ? null : AppTheme.surfaceLight,
            boxShadow: isReady
                ? [
                    BoxShadow(
                      color: AppTheme.accent
                          .withValues(alpha: 0.2 + 0.15 * _scanPulseAnim.value),
                      blurRadius: 20 + 10 * _scanPulseAnim.value,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: _iniciarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: isReady ? Colors.white : AppTheme.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Escanear QR y Registrar',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isReady ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

