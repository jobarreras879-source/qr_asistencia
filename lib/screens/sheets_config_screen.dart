import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';

class SheetsConfigScreen extends StatefulWidget {
  const SheetsConfigScreen({super.key});

  @override
  State<SheetsConfigScreen> createState() => _SheetsConfigScreenState();
}

class _SheetsConfigScreenState extends State<SheetsConfigScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isSyncing = false;
  GoogleSignInAccount? _account;
  Map<String, dynamic>? _sheetsInfo;
  bool _autoSync = false;
  String _currentRole = 'USUARIO';

  @override
  void initState() {
    super.initState();
    _initSheets();
  }

  Future<void> _initSheets() async {
    setState(() => _isLoading = true);

    final currentRole = await AuthService.getCurrentUserRole();
    if (!mounted) return;

    if (currentRole.toUpperCase() != 'ADMIN') {
      setState(() {
        _currentRole = currentRole;
        _isLoading = false;
      });
      return;
    }

    final info = await GoogleDriveService.getSheetsInfo();
    final autoSync = await GoogleDriveService.isAutoSyncEnabled();
    final account = await GoogleDriveService.signInSilently();

    if (!mounted) return;

    setState(() {
      _currentRole = currentRole;
      _sheetsInfo = info;
      _autoSync = autoSync;
      _account = account;
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final account = await GoogleDriveService.signIn(context: context);

    if (!mounted) return;
    setState(() {
      _account = account;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await GoogleDriveService.signOut();
    await GoogleDriveService.clearSheetsInfo();

    if (!mounted) return;
    setState(() {
      _account = null;
      _sheetsInfo = null;
      _autoSync = false;
    });
  }

  Future<void> _createSpreadsheet() async {
    final createController = TextEditingController(
      text: 'Asistencia AVS Ingeniería',
    );
    final searchController = TextEditingController();
    bool isSearching = true;
    List<Map<String, String>> searchResults = [];

    GoogleDriveService.searchSpreadsheets('').then((results) {
      searchResults = results;
      isSearching = false;
    });

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: double.maxFinite,
                height: 480,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Configurar Google Sheets',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre de la hoja',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: createController,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: AppTheme.inputDecoration(
                                hint: 'Ej: Asistencia 2024',
                                prefixIcon: Icons.table_chart_rounded,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _doCreateSpreadsheet(
                                    createController.text.trim(),
                                  );
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  'Crear Hoja',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _doLinkSpreadsheet(String id, String name, String url) async {
    setState(() => _isCreating = true);
    await GoogleDriveService.setSheetsInfo(id, name, url);
    final info = await GoogleDriveService.getSheetsInfo();
    if (!mounted) return;
    setState(() {
      _sheetsInfo = info;
      _autoSync = true;
      _isCreating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hoja vinculada exitosamente'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _doCreateSpreadsheet(String name) async {
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    final sheet = await GoogleDriveService.createSpreadsheet(name);

    if (!mounted) return;

    if (sheet != null && sheet.spreadsheetId != null) {
      final url =
          sheet.spreadsheetUrl ??
          'https://docs.google.com/spreadsheets/d/${sheet.spreadsheetId}';
      await GoogleDriveService.setSheetsInfo(sheet.spreadsheetId!, name, url);
      final info = await GoogleDriveService.getSheetsInfo();

      if (!mounted) return;
      setState(() {
        _sheetsInfo = info;
        _autoSync = true;
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoja de cálculo vinculada exitosamente'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la hoja de cálculo'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncHistory() async {
    if (_sheetsInfo == null) return;

    if (_currentRole.toUpperCase() != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo los administradores pueden exportar el historial completo.',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final data = await Supabase.instance.client
          .from('registros')
          .select()
          .order('fecha_hora', ascending: true);

      // Batch sync to Google Sheets
      final success = await GoogleDriveService.appendAttendanceRows(
        _sheetsInfo!['id'],
        List<Map<String, dynamic>>.from(data),
      );

      if (!mounted) return;
      setState(() => _isSyncing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
              ? 'Sincronización de ${data.length} registros exitosa.'
              : 'Error al sincronizar los registros.',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la exportación.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Sheets (Historial)',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sincroniza registros con Excel',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentRole.toUpperCase() != 'ADMIN') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Acceso restringido',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Solo los administradores pueden vincular o exportar Google Sheets.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_account == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  size: 40,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Conecta tu cuenta de Google',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Los registros de asistencia se sincronizarán en Google Sheets.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _signIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: Text(
                  'Iniciar con Google',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.elevatedCardDecoration,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _account!.photoUrl != null
                      ? NetworkImage(_account!.photoUrl!)
                      : null,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: _account!.photoUrl == null
                      ? const Icon(Icons.person, color: AppTheme.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account!.displayName ?? 'Usuario de Google',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _account!.email,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  onPressed: _signOut,
                  tooltip: 'Desconectar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_sheetsInfo == null)
            _buildNoSheetView()
          else
            _buildActiveSheetView(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNoSheetView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        children: [
          Icon(Icons.file_copy_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Sin hoja vinculada',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea o vincula una hoja de cálculo para sincronizar la asistencia.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _isCreating
              ? const CircularProgressIndicator(color: AppTheme.success)
              : ElevatedButton.icon(
                  onPressed: _createSpreadsheet,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    'Crear Nueva Hoja',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActiveSheetView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppTheme.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoja vinculada',
                      style: GoogleFonts.inter(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _sheetsInfo!['name'],
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sincronización Automática',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Agrega fila al Excel cada vez que se escanea',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoSync,
                  onChanged: (val) async {
                    await GoogleDriveService.setAutoSync(val);
                    setState(() => _autoSync = val);
                  },
                  activeColor: AppTheme.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _syncHistory,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    _isSyncing ? 'Sincronizando...' : 'Exportar historial',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: const BorderSide(color: AppTheme.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
