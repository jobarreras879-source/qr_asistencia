import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';

class DriveConfigScreen extends StatefulWidget {
  const DriveConfigScreen({super.key});

  @override
  State<DriveConfigScreen> createState() => _DriveConfigScreenState();
}

class _DriveConfigScreenState extends State<DriveConfigScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  GoogleSignInAccount? _account;
  List<drive.File> _folders = [];
  String? _selectedFolderId;
  String? _selectedFolderName;

  @override
  void initState() {
    super.initState();
    _initDrive();
  }

  Future<void> _initDrive() async {
    setState(() => _isLoading = true);

    final folderId = await GoogleDriveService.getDriveFolderId();
    final folderName = await GoogleDriveService.getDriveFolderName();
    final account = await GoogleDriveService.signInSilently();

    if (!mounted) return;

    setState(() {
      _selectedFolderId = folderId;
      _selectedFolderName = folderName;
      _account = account;
    });

    if (account != null) {
      await _loadFolders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await GoogleDriveService.listFolders();
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final account = await GoogleDriveService.signIn(context: context);

    if (!mounted) return;
    setState(() => _account = account);

    if (account != null) {
      await _loadFolders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleDriveService.signOut();
    await GoogleDriveService.clearDriveFolder();

    if (!mounted) return;
    setState(() {
      _account = null;
      _folders = [];
      _selectedFolderId = null;
      _selectedFolderName = null;
    });
  }

  Future<void> _selectFolder(drive.File folder) async {
    if (folder.id == null || folder.name == null) return;

    await GoogleDriveService.setDriveFolder(folder.id!, folder.name!);
    if (!mounted) return;

    setState(() {
      _selectedFolderId = folder.id;
      _selectedFolderName = folder.name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Carpeta seleccionada: ${folder.name}'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _createFolderDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createNewFolder(controller.text.trim());
              },
              style: AppTheme.primaryButton,
              child: Text(
                'Crear',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewFolder(String name) async {
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    final newFolder = await GoogleDriveService.createFolder(name);
    setState(() => _isCreating = false);

    if (newFolder != null) {
      await _selectFolder(newFolder);
      await _loadFolders();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la carpeta'),
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
                  'Google Drive (Fotos)',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Configura el almacenamiento de evidencias',
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
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add_to_drive_rounded,
                  size: 40,
                  color: Color(0xFF4285F4),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Conecta tu cuenta de Google Drive',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Las fotos tomadas como evidencia de asistencia se guardarán en la carpeta que elijas.',
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
        if (_selectedFolderId != null) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carpeta seleccionada:',
                        style: GoogleFonts.inter(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedFolderName ?? 'Carpeta desconocida',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off_rounded, color: AppTheme.error),
                  onPressed: _confirmUnlinkDrive,
                  tooltip: 'Desvincular globalmente',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Carpetas en Drive',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: _createFolderDialog,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Nueva'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: _folders.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron carpetas',
                            style: GoogleFonts.inter(color: AppTheme.textMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFolders,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _folders.length,
                            itemBuilder: (context, index) {
                              final folder = _folders[index];
                              final isSelected = folder.id == _selectedFolderId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.08)
                                      : AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    isSelected
                                        ? Icons.folder_special_rounded
                                        : Icons.folder_rounded,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                  title: Text(
                                    folder.name ?? 'Sin nombre',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppTheme.primary,
                                        )
                                      : null,
                                  onTap: () => _selectFolder(folder),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _confirmUnlinkDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desvincular carpeta?'),
        content: const Text(
          'Esta acción eliminará la vinculación de esta carpeta de fotos para TODOS los usuarios de la empresa. Deberás vincular una nueva si deseas seguir guardando fotos.',
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
      await GoogleDriveService.clearDriveFolder(global: true);
      await _initDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carpeta desvinculada globalmente'),
            backgroundColor: AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
