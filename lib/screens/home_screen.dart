import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import 'drive_config_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'project_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'sheets_config_screen.dart';
import 'user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final String usuario;
  final String rol;

  const HomeScreen({super.key, required this.usuario, required this.rol});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _blueprintTop = Color(0xFF0B2E8A);
  static const _blueprintBottom = Color(0xFF071D63);

  bool _hasInternet = false;
  List<Map<String, dynamic>> _proyectos = [];
  Map<String, dynamic>? _proyectoSeleccionado;
  late String _usuario;
  late String _rol;

  int _registrosHoy = 0;
  int _proyectosActivos = 0;

  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _rol = widget.rol;

    _startConnectivityMonitoring();
    _loadHomeData();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  bool get _isAdmin => _rol.toUpperCase() == 'ADMIN';

  void _startConnectivityMonitoring() {
    _checkInternetConnection();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _checkInternetConnection(),
    );
  }

  Future<void> _checkInternetConnection() async {
    var hasInternet = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      hasInternet = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      hasInternet = false;
    } catch (_) {
      hasInternet = false;
    }

    if (!mounted || _hasInternet == hasInternet) return;
    setState(() {
      _hasInternet = hasInternet;
    });
  }

  Future<void> _loadHomeData() async {
    final hasSession = await _refreshSession();
    if (!mounted || !hasSession) return;
    await _fetchData();
  }

  Future<void> _fetchData() async {
    final proyectosFuture = ProjectService.getProyectos();
    final registrosHoyFuture = AttendanceService.getTodayCount(_usuario);

    final proys = await proyectosFuture;
    final registrosHoy = await registrosHoyFuture;

    if (!mounted) return;

    final selectedNumber = _proyectoSeleccionado?['numero']?.toString();
    Map<String, dynamic>? proyectoSeleccionado;

    if (selectedNumber != null) {
      for (final proyecto in proys) {
        if (proyecto['numero']?.toString() == selectedNumber) {
          proyectoSeleccionado = Map<String, dynamic>.from(proyecto);
          break;
        }
      }
    }

    setState(() {
      _proyectos = proys;
      _proyectosActivos = proys.length;
      _registrosHoy = registrosHoy;
      _proyectoSeleccionado = proyectoSeleccionado;
    });
  }

  Future<bool> _refreshSession() async {
    final session = await AuthService.restoreSession();
    if (!mounted) return false;

    if (session == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return false;
    }

    setState(() {
      _usuario = session['usuario']!;
      _rol = session['rol']!;
    });

    return true;
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _iniciarRegistro() {
    final proyecto = _proyectoSeleccionado;
    if (proyecto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un proyecto primero'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final numero = proyecto['numero']?.toString() ?? '';
    final nombre = proyecto['nombre']?.toString() ?? '';
    final cliente = proyecto['cliente']?.toString() ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          usuario: _usuario,
          rol: _rol,
          projectNumber: numero,
          projectName: nombre,
          projectClient: cliente,
          tipo: 'Proyecto',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 18),
                    _buildProjectSection(),
                    const SizedBox(height: 18),
                    _buildActionsSection(),
                  ],
                ),
              ),
            ),
            _buildCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blueprintTop, _blueprintBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BlueprintGridPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _usuario,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _rol.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
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

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: '$_registrosHoy',
            label: 'Registros hoy',
            valueColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '$_proyectosActivos',
            label: 'Proyectos activos',
            valueColor: const Color(0xFF18B4AA),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frente de Trabajo',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _proyectoSeleccionado?['numero']?.toString(),
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textSecondary,
              ),
              hint: Text(
                'Seleccione un proyecto',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
              items: _proyectos.map((proyecto) {
                final numero = proyecto['numero']?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: numero,
                  child: Text(
                    _projectDropdownLabel(proyecto),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (valor) {
                if (valor == null) return;
                Map<String, dynamic>? proyectoSeleccionado;
                for (final proyecto in _proyectos) {
                  if (proyecto['numero']?.toString() == valor) {
                    proyectoSeleccionado = Map<String, dynamic>.from(proyecto);
                    break;
                  }
                }
                setState(() {
                  _proyectoSeleccionado = proyectoSeleccionado;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    final actions = <_ActionItem>[
      if (_isAdmin) ...[
        _ActionItem(
          label: 'Proyectos',
          icon: Icons.folder_open_outlined,
          iconColor: AppTheme.primary,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProjectManagementScreen(),
              ),
            );
            _fetchData();
          },
        ),
        _ActionItem(
          label: 'Drive',
          icon: Icons.cloud_outlined,
          iconColor: const Color(0xFF10A6D9),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
          ),
        ),
        _ActionItem(
          label: 'Sheets',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF19B99A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
          ),
        ),
        _ActionItem(
          label: 'Historial',
          icon: Icons.history_rounded,
          iconColor: const Color(0xFFF39A21),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
        _ActionItem(
          label: 'Usuarios',
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF7A4DFF),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
      ] else
        _ActionItem(
          label: 'Historial',
          icon: Icons.history_rounded,
          iconColor: const Color(0xFFF39A21),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
      _ActionItem(
        label: 'Salir',
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFEF4444),
        onTap: _logout,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.98,
          ),
          itemBuilder: (_, index) => _buildActionTile(actions[index]),
        ),
      ],
    );
  }

  Widget _buildActionTile(_ActionItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.iconColor, size: 29),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final ready = _proyectoSeleccionado != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + bottomPadding),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: ready ? _iniciarRegistro : null,
          icon: Icon(
            Icons.qr_code_2_rounded,
            size: 22,
            color: Colors.white.withValues(alpha: ready ? 1 : 0.78),
          ),
          label: Text(
            'Iniciar Registro',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: ready ? 1 : 0.84),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ready ? AppTheme.primary : const Color(0xFF8FA4E7),
            disabledBackgroundColor: const Color(0xFF8FA4E7),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  String _projectDropdownLabel(Map<String, dynamic> proyecto) {
    final numero = proyecto['numero']?.toString() ?? '';
    final nombre = proyecto['nombre']?.toString() ?? '';
    if (nombre.isEmpty || nombre == 'Sin nombre') {
      return 'Proyecto #$numero';
    }
    return 'Proyecto #$numero - $nombre';
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 42.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
