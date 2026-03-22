import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'project_management_screen.dart';
import 'user_management_screen.dart';
import 'drive_config_screen.dart';
import 'sheets_config_screen.dart';

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
          tipo: 'Proyecto', // Ahora por defecto
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
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildProjectSelector(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVS Ingeniería',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 26,
                    letterSpacing: 3,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'REGISTRAR ASISTENCIA',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // User badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.15),
                        AppTheme.accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _usuarioActual,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor?.withValues(alpha: 0.5) ?? AppTheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              icon, 
              color: accentColor ?? AppTheme.textSecondary, 
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PROYECTO',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _isLoading
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration,
                child: const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppTheme.accent),
                  ),
                ),
              )
            : _proyectos.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppTheme.error, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No se encontraron proyectos. Verifica la configuración de tu base de datos.',
                            style: TextStyle(
                                color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: AppTheme.cardDecoration,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppTheme.surface,
                        value: _proyectoIdSeleccionado,
                        hint: Text(
                          '— Selecciona —',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                        icon: const Icon(Icons.unfold_more_rounded,
                            color: AppTheme.textSecondary, size: 20),
                        items: _proyectos.map((p) {
                          return DropdownMenuItem<String>(
                            value: p['numero'],
                            child: Text(
                              '${p['numero']} — ${p['nombre']}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _proyectoIdSeleccionado = val);
                        },
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final currentRol = _rolActual.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ACCIONES RÁPIDAS',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (currentRol == 'ADMIN') ...[
              _buildIconButton(
                icon: Icons.folder_copy_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectManagementScreen(),
                    ),
                  );
                  _fetchProyectos(); // Refresh after returning
                },
                tooltip: 'Proyectos',
                accentColor: AppTheme.accentTeal,
              ),
              _buildIconButton(
                icon: Icons.add_to_drive_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
                  );
                },
                tooltip: 'Google Drive (Fotos)',
                accentColor: const Color(0xFF4285F4),
              ),
              _buildIconButton(
                icon: Icons.table_chart_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
                  );
                },
                tooltip: 'Google Sheets (Historial)',
                accentColor: const Color(0xFF0F9D58),
              ),
            ],
            if (currentRol == 'ADMIN') ...[
              _buildIconButton(
                icon: Icons.people_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
                tooltip: 'Usuarios',
                accentColor: AppTheme.accent2,
              ),
            ],
            _buildIconButton(
              icon: Icons.history_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              tooltip: 'Historial',
            ),
            _buildIconButton(
              icon: Icons.logout_rounded,
              onTap: _logout,
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
      ],
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
