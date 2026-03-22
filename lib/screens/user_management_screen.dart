import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  late AnimationController _listController;

  static const List<String> _roles = ['ADMIN', 'USUARIO'];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await UserService.getUsuarios();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
    _listController.forward(from: 0);
  }

  Color _rolColor(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.accent;
      default:
        return AppTheme.accentTeal;
    }
  }

  IconData _rolIcon(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final bool isEditing = user != null;
    final userController =
        TextEditingController(text: user?['usuario'] ?? '');
    final passController = TextEditingController();
    String selectedRol = user?['rol'] ?? 'USUARIO';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.dialogDecoration,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_rounded
                              : Icons.person_add_alt_1_rounded,
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
                  ),
                  const SizedBox(height: 24),

                  // Username label
                  Text(
                    'NOMBRE DE USUARIO',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: userController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: AppTheme.inputDecoration(
                      hint: 'Ej: JPEREZ',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password label
                  Text(
                    isEditing
                        ? 'NUEVA CONTRASEÑA (dejar vacío para no cambiar)'
                        : 'CONTRASEÑA',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: AppTheme.inputDecoration(
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role label
                  Text(
                    'ROL',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role selector chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _roles.map((rol) {
                      final isSelected = selectedRol == rol;
                      final color = _rolColor(rol);
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedRol = rol),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : AppTheme.surfaceLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected ? color : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _rolIcon(rol),
                                size: 16,
                                color: isSelected
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
                                  color: isSelected
                                      ? color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
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
                          onPressed: () async {
                            final userName = userController.text.trim();
                            final pass = passController.text;

                            if (userName.isEmpty) return;
                            if (!isEditing && pass.isEmpty) return;

                            if (pass.isNotEmpty && pass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('La contraseña debe tener mínimo 6 caracteres.'),
                                  backgroundColor: AppTheme.warning,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                              return;
                            }

                            String? error;
                            if (isEditing) {
                              error = await UserService.editarUsuario(
                                user['id'] as String,
                                userName,
                                pass.isEmpty ? null : pass,
                                selectedRol,
                              );
                            } else {
                              error = await UserService.crearUsuario(
                                userName,
                                pass,
                                selectedRol,
                              );
                            }

                            if (!mounted) return;
                            if (error == null) {
                              Navigator.pop(context);
                              _loadUsers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(isEditing
                                          ? 'Usuario actualizado'
                                          : 'Usuario creado'),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $error'),
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                          style: AppTheme.primaryButton,
                          child: Text(isEditing ? 'Guardar' : 'Crear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.dialogDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: AppTheme.error, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Eliminar Usuario?',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se eliminará permanentemente el usuario "${user['usuario']}". Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
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
                      onPressed: () async {
                        final error =
                            await UserService.eliminarUsuario(user['id'] as String);
                        if (!mounted) return;
                        if (error == null) {
                          Navigator.pop(context);
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Usuario eliminado'),
                                ],
                              ),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $error'),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 8),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent))
                    : _users.isEmpty
                        ? _buildEmptyState()
                        : _buildUserList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        label: const Text('Nuevo Usuario'),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: AppTheme.accent,
        elevation: 8,
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
              decoration: AppTheme.glassDecoration
                  .copyWith(borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuarios',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    letterSpacing: 2,
                    color: AppTheme.accent,
                  ),
                ),
                Text(
                  'ADMINISTRACIÓN',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // User count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Text(
              '${_users.length}',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 56, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay usuarios',
            style: GoogleFonts.dmSans(
                fontSize: 18,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza creando uno nuevo',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final rol = user['rol'] as String;
        final color = _rolColor(rol);

        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            final double delay = (index * 0.1).clamp(0, 1.0);
            final double animValue = Curves.easeOutCubic.transform(
                (_listController.value - delay * 0.5).clamp(0, 1.0));

            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animValue)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                // Avatar with role icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Icon(
                      _rolIcon(rol),
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['usuario'] ?? 'Sin nombre',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          rol,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  onPressed: () => _showUserDialog(user: user),
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.textSecondary, size: 20),
                ),
                // Delete button
                if (AuthService.currentUserId != user['id'].toString())
                  IconButton(
                    onPressed: () => _confirmDelete(user),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
