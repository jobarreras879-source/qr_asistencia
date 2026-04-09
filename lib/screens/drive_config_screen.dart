import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/app_feedback_service.dart';
import '../services/drive_backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drive/drive_access_denied.dart';
import '../widgets/drive/drive_linked_state.dart';
import '../widgets/drive/drive_screen_header.dart';
import '../widgets/drive/drive_unlinked_state.dart';

/// Pantalla de configuración de Google Drive para ADMINISTRADORES.
///
/// Flujo:
///   1. El admin vincula su cuenta Google (backend recibe el refresh token).
///   2. El token se almacena cifrado en [configuracion_global].
///   3. El admin elige o crea una carpeta.
///   4. Los supervisores suben fotos sin necesitar sesión Google propia.
class DriveConfigScreen extends StatefulWidget {
  const DriveConfigScreen({super.key});

  @override
  State<DriveConfigScreen> createState() => _DriveConfigScreenState();
}

class _DriveConfigScreenState extends State<DriveConfigScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isAdmin = false;

  // Drive status from backend
  bool _linked = false;
  String? _linkedEmail;
  String? _selectedFolderId;
  String? _selectedFolderName;

  // Folders fetched from backend
  List<Map<String, String>> _folders = [];

  // GoogleSignIn solo para obtener el serverAuthCode del admin
  static final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConfig.googleServerClientId : null,
    serverClientId: AppConfig.googleServerClientId,
    forceCodeForRefreshToken: true,
    scopes: [
      'https://www.googleapis.com/auth/drive',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    final role = await AuthService.getCurrentUserRole();
    _isAdmin = role == 'ADMIN';

    if (!_isAdmin) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await DriveBackendService.getDriveStatus();
      if (!mounted) return;
      setState(() {
        _linked = status['linked'] == true;
        _linkedEmail = status['email'] as String?;
        _selectedFolderId = status['folderId'] as String?;
        _selectedFolderName = status['folderName'] as String?;
      });

      if (_linked) {
        await _loadFolders();
        return;
      }
    } catch (e) {
      _showError(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final folders = await DriveBackendService.listFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Error cargando carpetas: ${e.toString()}');
    }
  }

  /// Paso 1: el admin hace login con Google para obtener el serverAuthCode.
  /// Paso 2: se envía al backend para guardar el refresh token.
  Future<void> _linkDrive() async {
    setState(() => _isLoading = true);
    try {
      // Close any local session without revoking the backend refresh token.
      try { await _googleSignIn.signOut(); } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final serverAuthCode = account.serverAuthCode;
      if (serverAuthCode == null) {
        if (mounted) setState(() => _isLoading = false);
        _showError(
          'No se recibió el server auth code. '
          'Asegúrate de que el OAuth Client esté configurado con access_type=offline y prompt=consent.',
        );
        try { await _googleSignIn.signOut(); } catch (_) {}
        return;
      }

      await DriveBackendService.linkDrive(serverAuthCode);

      // Close only the local Google session. Do not revoke the stored refresh token.
      try { await _googleSignIn.signOut(); } catch (_) {}

      if (!mounted) return;
      _showSuccess('Google Drive vinculado correctamente');
      await _loadStatus();
    } on DriveBackendException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.message);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _unlinkDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Desvincular Drive?',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Esto eliminará la vinculación de Drive para TODOS los usuarios. '
          'Los supervisores no podrán subir fotos hasta que se vuelva a vincular.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await DriveBackendService.unlinkDrive();
      if (!mounted) return;
      _showInfo('Drive desvinculado globalmente');
      await _loadStatus();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _selectFolder(Map<String, String> folder) async {
    final id = folder['id']!;
    final name = folder['name']!;
    setState(() => _isLoading = true);
    try {
      await DriveBackendService.setFolder(id, name);
      if (!mounted) return;
      setState(() {
        _selectedFolderId = id;
        _selectedFolderName = name;
        _isLoading = false;
      });
      _showSuccess('Carpeta seleccionada: $name');
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _createFolderDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nueva Carpeta',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: AppTheme.inputDecoration(
            hint: 'Nombre de la carpeta',
            prefixIcon: Icons.create_new_folder_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createNewFolder(controller.text.trim());
            },
            style: AppTheme.primaryButton,
            child: Text('Crear', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewFolder(String name) async {
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final newFolder = await DriveBackendService.createFolder(name);
      await _selectFolder(newFolder);
      await _loadFolders();
    } catch (e) {
      _showError('Error al crear la carpeta: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  void _showSuccess(String msg) {
    if (!mounted) return;
    AppFeedbackService.showSnackBar(
      context,
      msg,
      type: AppFeedbackType.success,
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    AppFeedbackService.showSnackBar(
      context,
      msg,
      type: AppFeedbackType.error,
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    AppFeedbackService.showSnackBar(
      context,
      msg,
      type: AppFeedbackType.info,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            DriveScreenHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : !_isAdmin
                      ? const DriveAccessDenied()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_linked) {
      return DriveUnlinkedState(onLink: _linkDrive);
    }
    return DriveLinkedState(
      isCreating: _isCreating,
      linkedEmail: _linkedEmail,
      selectedFolderId: _selectedFolderId,
      selectedFolderName: _selectedFolderName,
      folders: _folders,
      onUnlink: _unlinkDrive,
      onCreateFolder: _createFolderDialog,
      onRefresh: _loadFolders,
      onSelectFolder: _selectFolder,
    );
  }
}
