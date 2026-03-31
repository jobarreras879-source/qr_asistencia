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
    return rol.toUpperCase() == 'ADMIN'
        ? AppTheme.primary
        : AppTheme.accentTeal;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final isCurrentUser =
        widget.user?['id']?.toString() == AuthService.currentUserId;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
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
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu propio usuario debe conservar el rol ADMIN mientras la sesión esté activa.',
                          style: GoogleFonts.inter(
                            color: AppTheme.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              isEditing
                  ? 'Actualiza los datos del usuario'
                  : 'Crea un nuevo perfil de acceso',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildRoleSelector({required bool isCurrentUser}) {
    return Row(
      children: _roles.map((rol) {
        final isSelected = _selectedRol == rol;
        final color = _rolColor(rol);
        final isDisabled = isCurrentUser && rol != 'ADMIN';
        return Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : () => setState(() => _selectedRol = rol),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: rol == 'ADMIN' ? 8 : 0,
                left: rol == 'USUARIO' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
                    : isSelected
                    ? color.withValues(alpha: 0.1)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? AppTheme.border
                      : isSelected
                      ? color
                      : AppTheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _rolIcon(rol),
                    size: 18,
                    color: isDisabled
                        ? AppTheme.textMuted
                        : isSelected
                        ? color
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rol,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
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
                : Text(
                    widget.user != null ? 'Guardar' : 'Crear',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
