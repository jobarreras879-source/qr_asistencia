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
    final createController = TextEditingController(text: 'Asistencia AVS Ingeniería');
    final searchController = TextEditingController();
    bool isSearching = true; // Empieza buscando automáticamente
    List<Map<String, String>> searchResults = [];

    // Llamamos a la búsqueda inicial antes o justo al abrir el diálogo
    GoogleDriveService.searchSpreadsheets('').then((results) {
      searchResults = results;
      isSearching = false;
    });

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              contentPadding: EdgeInsets.zero,
              content: DefaultTabController(
                length: 2,
                child: SizedBox(
                  width: double.maxFinite,
                  height: 480,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black26,
                        child: const TabBar(
                          indicatorColor: AppTheme.accent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(text: 'Crear Nueva'),
                            Tab(text: 'Buscar en Drive'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Pestaña Crear
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Crear Hoja de Cálculo',
                                    style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: createController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: AppTheme.inputDecoration(
                                      hint: 'Nombre del archivo',
                                      prefixIcon: Icons.table_chart_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _doCreateSpreadsheet(createController.text.trim());
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                                    child: const Text('Crear', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            // Pestaña Buscar
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: searchController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: AppTheme.inputDecoration(
                                            hint: 'Buscar hoja...',
                                            prefixIcon: Icons.search,
                                          ),
                                          onSubmitted: (val) async {
                                            setStateBuilder(() => isSearching = true);
                                            final results = await GoogleDriveService.searchSpreadsheets(val);
                                            setStateBuilder(() {
                                              searchResults = results;
                                              isSearching = false;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search, color: AppTheme.accent),
                                        onPressed: () async {
                                          setStateBuilder(() => isSearching = true);
                                          final results = await GoogleDriveService.searchSpreadsheets(searchController.text);
                                          setStateBuilder(() {
                                            searchResults = results;
                                            isSearching = false;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setInnerState) {
                                        // Refrescar automáticamente cuando isSearching cambie por el Future externo
                                        if (isSearching) {
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            if (mounted) setInnerState(() {});
                                          });
                                          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                                        }

                                        return searchResults.isEmpty
                                            ? const Center(
                                                child: Text(
                                                    'No se encontraron hojas de cálculo en tu Google Drive.\nUsa el buscador o crea una nueva.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: Colors.grey)))
                                            : ListView.builder(
                                                itemCount: searchResults.length,
                                                itemBuilder: (context, index) {
                                                  final file = searchResults[index];
                                                  return ListTile(
                                                    leading: const Icon(Icons.table_chart, color: Color(0xFF0F9D58)),
                                                    title: Text(file['name'] ?? 'Sin nombre',
                                                        style: const TextStyle(color: Colors.white)),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _doLinkSpreadsheet(file['id']!, file['name']!, file['link']!);
                                                    },
                                                  );
                                                },
                                              );
                                      },
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
        content: Text('Hoja existente vinculada exitosamente'),
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
      final url = sheet.spreadsheetUrl ?? 'https://docs.google.com/spreadsheets/d/${sheet.spreadsheetId}';
      await GoogleDriveService.setSheetsInfo(sheet.spreadsheetId!, name, url);
      
      final info = await GoogleDriveService.getSheetsInfo();
      
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

    // Solo ADMIN puede exportar todo el historial
    if (_currentRole.toUpperCase() != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo los administradores pueden exportar el historial completo.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      // 1. Fetch ALL records from Supabase
      final data = await Supabase.instance.client
          .from('registros')
          .select()
          .order('fecha_hora', ascending: true);

      int successCount = 0;
      int errorCount = 0;

      // 2. Append directly row by row (naïve approach but safe for limited data)
      for (var reg in data) {
        final success = await GoogleDriveService.appendAttendanceRow(
          _sheetsInfo!['id'],
          reg,
        );

        if (success) {
          successCount++;
        } else {
          errorCount++;
        }
      }

      if (!mounted) return;
      setState(() => _isSyncing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sincronización finalizada: $successCount exitosos, $errorCount errores.'),
          backgroundColor: errorCount > 0 ? AppTheme.warning : AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la exportación. Intenta de nuevo.'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Google Sheets (Historial)',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : _buildBody(),
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
              const Icon(Icons.lock_outline_rounded, color: AppTheme.warning, size: 56),
              const SizedBox(height: 16),
              Text(
                'Acceso restringido',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Solo los administradores pueden vincular o exportar Google Sheets.',
                style: GoogleFonts.dmSans(
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
              Icon(Icons.table_chart_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text(
                'Conecta tu cuenta de Google',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Los registros de asistencia se sincronizarán en una hoja de Google Sheets en la cuenta que conectes.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _signIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.white),
                label: const Text('Iniciar con Google', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Account Info Header ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _account!.photoUrl != null ? NetworkImage(_account!.photoUrl!) : null,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  child: _account!.photoUrl == null ? const Icon(Icons.person, color: AppTheme.accent) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account!.displayName ?? 'Usuario de Google',
                        style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _account!.email,
                        style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
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

          const SizedBox(height: 12),

          // --- Spreadsheet Management ---
          if (_sheetsInfo == null)
            _buildNoSheetView()
          else
            _buildActiveSheetView(),
        ],
      ),
    );
  }

  Widget _buildNoSheetView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Icon(Icons.file_copy_rounded, size: 60, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Sin hoja de cálculo vinculada',
            style: GoogleFonts.dmSans(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para exportar la asistencia, necesitas crear o elegir una hoja de Excel/Sheets en tu cuenta de Google.',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _isCreating
            ? const CircularProgressIndicator(color: Color(0xFF0F9D58))
            : ElevatedButton.icon(
                onPressed: _createSpreadsheet,
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                label: const Text('Crear Nueva Hoja', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58), // Google Sheets Green
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildActiveSheetView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F9D58).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0F9D58).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_rounded, color: Color(0xFF0F9D58), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _sheetsInfo!['name'],
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Auto-sync Toggle
              SwitchListTile(
                value: _autoSync,
                onChanged: (val) async {
                  await GoogleDriveService.setAutoSync(val);
                  setState(() => _autoSync = val);
                },
                title: Text(
                  'Sincronización Automática',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Agrega fila al Excel cada vez que se escanea un QR',
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 12),
                ),
                activeColor: const Color(0xFF0F9D58),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(color: AppTheme.borderLight, height: 32),

              // Sincronizar Historial Manualmente
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exportar registros actuales',
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Envía el historial que ya existe en la nube.',
                          style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _isSyncing
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F9D58), strokeWidth: 2)),
                      )
                    : ElevatedButton.icon(
                        onPressed: _syncHistory,
                        icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                        label: const Text('Sincronizar', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text('¿Desvincular hoja?', style: TextStyle(color: Colors.white)),
                content: const Text('Esto no borrará el archivo de Google Drive, solo dejará de sincronizar aquí.', style: TextStyle(color: AppTheme.textSecondary)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await GoogleDriveService.clearSheetsInfo();
                      setState(() => _sheetsInfo = null);
                    },
                    child: const Text('Desvincular', style: TextStyle(color: AppTheme.error)),
                  )
                ],
              ),
            );
          },
          icon: const Icon(Icons.link_off_rounded, color: AppTheme.error, size: 18),
          label: const Text('Desvincular Excel actual', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }
}
