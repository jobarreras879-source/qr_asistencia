import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/attendance_service.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';
import 'login_screen.dart';
import 'project_management_screen.dart';
import 'drive_config_screen.dart';
import 'sheets_config_screen.dart';
import 'user_management_screen.dart';
import 'history_screen.dart';

// ─── Paleta local (complementa AppTheme) ────────────────────────────
class _C {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF111622);
  static const surface2 = Color(0xFF1A2235);
  static const border = Color(0xFF1E2535);
  static const border2 = Color(0xFF2A3650);
  static const textPri = Color(0xFFE8EAF0);
  static const textSec = Color(0xFF8B9099);
  static const textMuted = Color(0xFF5A6070);
  static const blue = Color(0xFF4A90D9);
  static const green = Color(0xFF2DB67C);
  static const amber = Color(0xFFD4910A);
  static const purple = Color(0xFF8B6FD4);
  static const teal = Color(0xFF1AAA8A);
  static const red = Color(0xFFC45A5A);
}

class HomeScreen extends StatefulWidget {
  final String usuario;
  final String rol;

  const HomeScreen({super.key, required this.usuario, required this.rol});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasInternet = false;
  List<Map<String, dynamic>> _proyectos = [];
  String? _proyectoIdSeleccionado;
  String? _proyectoNombreSeleccionado;
  late String _usuario;
  late String _rol;

  int _registrosHoy = 0;
  int _proyectosActivos = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _rol = widget.rol;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();

    _startConnectivityMonitoring();
    _loadHomeData();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startConnectivityMonitoring() {
    _checkInternetConnection();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _checkInternetConnection(),
    );
  }

  Future<void> _checkInternetConnection() async {
    bool hasInternet;

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
    setState(() => _isLoading = true);

    final proyectosFuture = ProjectService.getProyectos();
    final registrosHoyFuture = AttendanceService.getTodayCount(_usuario);

    final proys = await proyectosFuture;
    final registrosHoy = await registrosHoyFuture;

    if (!mounted) return;

    String? proyectoIdSeleccionado = _proyectoIdSeleccionado;
    String? proyectoNombreSeleccionado = _proyectoNombreSeleccionado;

    if (proyectoIdSeleccionado != null) {
      Map<String, dynamic>? proyectoSeleccionado;
      for (final proyecto in proys) {
        if (proyecto['numero']?.toString() == proyectoIdSeleccionado) {
          proyectoSeleccionado = proyecto;
          break;
        }
      }

      if (proyectoSeleccionado == null) {
        proyectoIdSeleccionado = null;
        proyectoNombreSeleccionado = null;
      } else {
        proyectoNombreSeleccionado =
            '${proyectoSeleccionado['numero']} — ${proyectoSeleccionado['nombre']}';
      }
    }

    setState(() {
      _proyectos = proys;
      _proyectosActivos = proys.length;
      _registrosHoy = registrosHoy;
      _proyectoIdSeleccionado = proyectoIdSeleccionado;
      _proyectoNombreSeleccionado = proyectoNombreSeleccionado;
      _isLoading = false;
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
    if (_proyectoIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un proyecto primero'),
          backgroundColor: AppTheme.accent2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          usuario: _usuario,
          rol: _rol,
          proyectoInfo: _proyectoIdSeleccionado!,
          tipo: 'Proyecto',
        ),
      ),
    );
  }

  String get _initials {
    final parts = _usuario
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.isEmpty) return 'US';

    final value = parts.first;
    return value.length >= 2
        ? value.substring(0, 2).toUpperCase()
        : value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildHero(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStats(),
                      const SizedBox(height: 20),
                      _buildProjectSection(),
                      const SizedBox(height: 20),
                      _buildActionsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildCTA(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      color: _C.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVS Ingeniería',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _C.textPri,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Control de asistencia',
                    style: GoogleFonts.dmSans(fontSize: 13, color: _C.blue),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.border2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [_buildUserBadge(), _buildRoleBadge()],
          ),
        ],
      ),
    );
  }

  Widget _buildUserBadge() {
    final statusColor = _hasInternet ? _C.green : _C.red;
    final statusLabel = _hasInternet ? 'Con internet' : 'Sin internet';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _C.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusLabel,
                style: GoogleFonts.dmSans(fontSize: 11, color: _C.textSec),
              ),
              Text(
                _usuario,
                style: GoogleFonts.dmSans(fontSize: 13, color: _C.textPri),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3D1E)),
      ),
      child: Text(
        _rol.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _C.green,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$_registrosHoy',
            label: 'Registros hoy',
            badge: _registrosHoy > 0 ? 'actividad del dia' : 'sin registros',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$_proyectosActivos',
            label: 'Proyectos activos',
            badge: 'operativos',
          ),
        ),
      ],
    );
  }

  Widget _buildProjectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Frente de trabajo'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proyecto seleccionado',
                style: GoogleFonts.dmSans(fontSize: 12, color: _C.textSec),
              ),
              const SizedBox(height: 4),
              Text(
                _proyectoNombreSeleccionado ?? 'Sin selección',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _proyectoNombreSeleccionado != null
                      ? _C.textPri
                      : _C.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: _C.blue,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _buildProjectDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: _C.surface,
          value: _proyectoIdSeleccionado,
          hint: Text(
            'Cambiar proyecto',
            style: GoogleFonts.dmSans(color: _C.textSec, fontSize: 14),
          ),
          icon: const Icon(
            Icons.unfold_more_rounded,
            color: _C.textMuted,
            size: 20,
          ),
          items: _proyectos.map((proyecto) {
            final numero = proyecto['numero']?.toString() ?? '';
            final nombre = proyecto['nombre']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: numero,
              child: Text(
                '$numero — $nombre',
                style: GoogleFonts.dmSans(color: _C.textPri, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (valor) {
            if (valor == null) return;

            Map<String, dynamic>? proyectoSeleccionado;
            for (final proyecto in _proyectos) {
              if (proyecto['numero']?.toString() == valor) {
                proyectoSeleccionado = proyecto;
                break;
              }
            }

            if (proyectoSeleccionado == null) return;
            final proyectoNumero = proyectoSeleccionado['numero'];
            final proyectoNombre = proyectoSeleccionado['nombre'];

            setState(() {
              _proyectoIdSeleccionado = valor;
              _proyectoNombreSeleccionado = '$proyectoNumero — $proyectoNombre';
            });
          },
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final isAdmin = _rol.toUpperCase() == 'ADMIN';

    final actions = <_ActionItem>[
      if (isAdmin) ...[
        _ActionItem(
          label: 'Proyectos',
          iconColor: _C.blue,
          bgColor: const Color(0xFF0E1E3A),
          icon: Icons.grid_view_rounded,
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
          iconColor: _C.amber,
          bgColor: const Color(0xFF221A08),
          icon: Icons.add_to_drive_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
          ),
        ),
        _ActionItem(
          label: 'Sheets',
          iconColor: _C.green,
          bgColor: const Color(0xFF0D2018),
          icon: Icons.table_chart_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
          ),
        ),
        _ActionItem(
          label: 'Usuarios',
          iconColor: _C.purple,
          bgColor: const Color(0xFF180F2E),
          icon: Icons.people_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
      ],
      _ActionItem(
        label: 'Historial',
        iconColor: _C.teal,
        bgColor: const Color(0xFF0A1E1A),
        icon: Icons.history_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        ),
      ),
      _ActionItem(
        label: 'Salir',
        iconColor: _C.red,
        bgColor: const Color(0xFF1E1518),
        icon: Icons.logout_rounded,
        onTap: _logout,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Acciones'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, index) => _buildActionTile(actions[index]),
        ),
      ],
    );
  }

  Widget _buildActionTile(_ActionItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: GoogleFonts.dmSans(fontSize: 12, color: _C.textSec),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final ready = _proyectoIdSeleccionado != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _iniciarRegistro,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: ready ? const Color(0xFF1A3A6E) : _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ready ? const Color(0xFF2A5098) : _C.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ready ? const Color(0xFF2255A8) : _C.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: ready ? Colors.white : _C.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Iniciar registro',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ready ? _C.textPri : _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: _C.textMuted,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String badge;

  const _StatCard({
    required this.value,
    required this.label,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2535)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _C.textPri,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12, color: _C.textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2018),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: _C.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });
}
