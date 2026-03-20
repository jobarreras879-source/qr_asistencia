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
    
    // Check local preferences
    final folderId = await GoogleDriveService.getDriveFolderId();
    final folderName = await GoogleDriveService.getDriveFolderName();
    
    // Check silent login
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
      ),
    );
  }

  Future<void> _createFolderDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            'Nueva Carpeta',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration(
              hint: 'Nombre de la carpeta',
              prefixIcon: Icons.create_new_folder_rounded,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createNewFolder(controller.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Google Drive (Fotos)',
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
    if (_account == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_to_drive_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                'Conecta tu cuenta de Google Drive',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Las fotos tomadas como evidencia de asistencia se guardarán en la carpeta que elijas.',
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
                  backgroundColor: const Color(0xFF4285F4), // Google Blue
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
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
                backgroundColor: AppTheme.accent.withOpacity(0.2),
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

        // --- Current Selected Folder ---
        if (_selectedFolderId != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carpeta seleccionada para fotos:',
                        style: GoogleFonts.dmSans(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedFolderName ?? 'Carpeta desconocida',
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // --- Folders List ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tus Carpetas',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _isCreating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            onPressed: _createFolderDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nueva'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                          ),
                    ],
                  ),
                ),

                Expanded(
                  child: _folders.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron carpetas',
                          style: GoogleFonts.dmSans(color: AppTheme.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFolders,
                        color: AppTheme.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final folder = _folders[index];
                            final isSelected = folder.id == _selectedFolderId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accent : AppTheme.border.withOpacity(0.5),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isSelected ? Icons.folder_special_rounded : Icons.folder_rounded,
                                  color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                                ),
                                title: Text(
                                  folder.name ?? 'Sin nombre',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.accent)
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
}
