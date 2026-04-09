import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_service.dart';
import '../services/app_feedback_service.dart';
import '../services/google_drive_service.dart';
import '../services/sheets_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sheets/sheets_access_denied.dart';
import '../widgets/sheets/sheets_account_card.dart';
import '../widgets/sheets/sheets_active_sheet_view.dart';
import '../widgets/sheets/sheets_connect_state.dart';
import '../widgets/sheets/sheets_no_sheet_view.dart';
import '../widgets/sheets/sheets_screen_header.dart';

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

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            // Load initial search results if not loaded
            if (isSearching && searchResults.isEmpty && searchController.text.isEmpty) {
              GoogleDriveService.searchSpreadsheets('').then((results) {
                if (context.mounted) {
                  setStateBuilder(() {
                    searchResults = results;
                    isSearching = false;
                  });
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: double.maxFinite,
                height: 520, // Increased height to accommodate the search list
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Google Sheets',
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
                            const TabBar(
                              indicatorColor: AppTheme.success,
                              labelColor: AppTheme.success,
                              unselectedLabelColor: AppTheme.textSecondary,
                              tabs: [
                                Tab(text: 'Vincular Existente'),
                                Tab(text: 'Crear Nueva'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Buscar y Vincular
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: searchController,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary,
                                    ),
                                    onChanged: (value) async {
                                      setStateBuilder(() => isSearching = true);
                                      final results = await GoogleDriveService
                                          .searchSpreadsheets(value);
                                      if (context.mounted) {
                                        setStateBuilder(() {
                                          searchResults = results;
                                          isSearching = false;
                                        });
                                      }
                                    },
                                    decoration: AppTheme.inputDecoration(
                                      hint: 'Buscar en Drive...',
                                      prefixIcon: Icons.search_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: isSearching
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.success,
                                            ),
                                          )
                                        : searchResults.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No se encontraron hojas de cálculo',
                                                  style: GoogleFonts.inter(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: searchResults.length,
                                                itemBuilder: (context, index) {
                                                  final sheet = searchResults[index];
                                                  return ListTile(
                                                    leading: const Icon(
                                                      Icons.table_chart_rounded,
                                                      color: AppTheme.success,
                                                    ),
                                                    title: Text(
                                                      sheet['name'] ?? '',
                                                      style: GoogleFonts.inter(
                                                        color: AppTheme.textPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _doLinkSpreadsheet(
                                                        sheet['id']!,
                                                        sheet['name']!,
                                                        sheet['link']!,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                  ),
                                ],
                              ),
                            ),
                            // Tab 2: Crear Nueva
                            Padding(
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
                                      prefixIcon: Icons.add_box_rounded,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _doCreateSpreadsheet(
                                          createController.text.trim(),
                                        );
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 20),
                                      label: Text(
                                        'Crear y Vincular',
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
    AppFeedbackService.showSnackBar(
      context,
      'Hoja vinculada exitosamente',
      type: AppFeedbackType.success,
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

      AppFeedbackService.showSnackBar(
        context,
        'Hoja de cálculo vinculada exitosamente',
        type: AppFeedbackType.success,
      );
    } else {
      setState(() => _isCreating = false);
      AppFeedbackService.showSnackBar(
        context,
        'Error al crear la hoja de cálculo',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _syncHistory() async {
    if (_sheetsInfo == null) return;

    if (_currentRole.toUpperCase() != 'ADMIN') {
      AppFeedbackService.showSnackBar(
        context,
        'Solo los administradores pueden exportar el historial completo.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final result = await SheetsSyncService.exportHistory(_sheetsInfo!['id']);

      if (!mounted) return;
      setState(() => _isSyncing = false);

      AppFeedbackService.showSnackBar(
        context,
        'Sincronización: ${result.successCount} exitosos, ${result.errorCount} errores.',
        type: result.errorCount > 0
            ? AppFeedbackType.warning
            : AppFeedbackType.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      AppFeedbackService.showSnackBar(
        context,
        'No se pudo completar la exportación.',
        type: AppFeedbackType.error,
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
            SheetsScreenHeader(onBack: () => Navigator.pop(context)),
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

  Widget _buildBody() {
    if (_currentRole.toUpperCase() != 'ADMIN') {
      return const SheetsAccessDenied();
    }

    if (_account == null) {
      return SheetsConnectState(onSignIn: _signIn);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetsAccountCard(account: _account!, onSignOut: _signOut),
          const SizedBox(height: 20),
          if (_sheetsInfo == null)
            SheetsNoSheetView(
              isCreating: _isCreating,
              onCreateSpreadsheet: _createSpreadsheet,
            )
          else
            SheetsActiveSheetView(
              sheetsInfo: _sheetsInfo!,
              autoSync: _autoSync,
              isSyncing: _isSyncing,
              onAutoSyncChanged: (val) async {
                await GoogleDriveService.setAutoSync(val);
                if (!mounted) return;
                setState(() => _autoSync = val);
              },
              onSyncHistory: _syncHistory,
              onConfirmUnlink: _confirmUnlink,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmUnlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desvincular hoja?'),
        content: const Text(
          'Esta acción eliminará la vinculación de esta hoja de cálculo para TODOS los usuarios de la empresa. Deberás vincular una nueva si deseas seguir sincronizando.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GoogleDriveService.clearSheetsInfo(global: true);
      await _initSheets();
      if (mounted) {
        AppFeedbackService.showSnackBar(
          context,
          'Hoja desvinculada globalmente',
          type: AppFeedbackType.info,
        );
      }
    }
  }
}
