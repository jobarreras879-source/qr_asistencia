import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class UserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;

  const UserDialog({super.key, this.user});

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  late TextEditingController _userController;
  late TextEditingController _passController;
  late String _selectedRol;
  bool _obscurePassword = true;
  bool _isSaving = false;

  static const List<String> _roles = ['ADMIN', 'USUARIO'];

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(
      text: widget.user?['usuario'] ?? '',
    );
    _passController = TextEditingController();
    _selectedRol = widget.user?['rol'] ?? 'USUARIO';
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Color _rolColor(String rol) {
    return rol.toUpperCase() == 'ADMIN' ? AppTheme.accent : AppTheme.accentTeal;
  }

  IconData _rolIcon(String rol) {
    return rol.toUpperCase() == 'ADMIN'
        ? Icons.admin_panel_settings_rounded
        : Icons.person_rounded;
  }

  Future<void> _save() async {
    final userName = _userController.text.trim();
    final pass = _passController.text;
    final isEditing = widget.user != null;

    if (userName.isEmpty) return;
    if (!isEditing && pass.isEmpty) return;
    if (pass.isNotEmpty && pass.length < 6) {
      _showError('La contraseña debe tener mínimo 6 caracteres.');
      return;
    }

    setState(() => _isSaving = true);
    String? error;
    if (isEditing) {
      error = await UserService.editarUsuario(
        widget.user!['id'] as String,
        userName,
        pass.isEmpty ? null : pass,
        _selectedRol,
      );
    } else {
      error = await UserService.crearUsuario(userName, pass, _selectedRol);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      _showError(error);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $msg'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final isCurrentUser =
        widget.user?['id']?.toString() == AuthService.currentUserId;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.dialogDecoration,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 24),
              _buildLabel('NOMBRE DE USUARIO'),
              const SizedBox(height: 8),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppTheme.inputDecoration(
                  hint: 'Ej: JPEREZ',
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel(
                isEditing ? 'NUEVA CONTRASEÑA (opcional)' : 'CONTRASEÑA',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppTheme.inputDecoration(
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('ROL'),
              const SizedBox(height: 10),
              _buildRoleSelector(isCurrentUser: isCurrentUser),
              if (isCurrentUser) ...[
                const SizedBox(height: 8),
                Text(
                  'Tu propio usuario debe conservar el rol ADMIN mientras la sesión esté activa.',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
            color: AppTheme.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildRoleSelector({required bool isCurrentUser}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map((rol) {
        final isSelected = _selectedRol == rol;
        final color = _rolColor(rol);
        final isDisabled = isCurrentUser && rol != 'ADMIN';
        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => _selectedRol = rol),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppTheme.surfaceLight.withValues(alpha: 0.25)
                  : isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? AppTheme.border.withValues(alpha: 0.5)
                    : isSelected
                    ? color
                    : AppTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _rolIcon(rol),
                  size: 16,
                  color: isDisabled
                      ? AppTheme.textMuted
                      : isSelected
                      ? color
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  rol,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDisabled
                        ? AppTheme.textMuted
                        : isSelected
                        ? color
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.secondaryButton,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: AppTheme.primaryButton,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.user != null ? 'Guardar' : 'Crear'),
          ),
        ),
      ],
    );
  }
}
