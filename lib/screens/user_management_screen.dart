import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_card.dart';
import '../widgets/user_dialog.dart';

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

  void _openDialog({Map<String, dynamic>? user}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UserDialog(user: user),
    );
    if (!mounted) return;
    if (result == true) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(user != null ? 'Usuario actualizado' : 'Usuario creado'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                  color: AppTheme.error.withValues(alpha: 0.1),
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
                      onPressed: () => Navigator.pop(ctx),
                      style: AppTheme.secondaryButton,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final error = await UserService.eliminarUsuario(
                            user['id'] as String);
                        if (!mounted) return;
                        if (error == null) {
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(children: [
                                Icon(Icons.delete_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Usuario eliminado'),
                              ]),
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
                        child: CircularProgressIndicator(color: AppTheme.accent))
                    : _users.isEmpty
                        ? _buildEmptyState()
                        : _buildUserList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.headerGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
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
                    'Gestion de usuarios',
                    style: GoogleFonts.ibmPlexSerif(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra accesos y perfiles operativos.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent2.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent2.withValues(alpha: 0.35)),
              ),
              child: Text(
                '${_users.length}',
                style: GoogleFonts.ibmPlexSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent2Light,
                  fontSize: 12,
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
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 56, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay usuarios',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 18,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza creando uno nuevo',
            style: GoogleFonts.ibmPlexSans(color: AppTheme.textMuted),
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
        final delay = (index * 0.1).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _listController,
          builder: (context, _) {
            final animValue = Curves.easeOutCubic.transform(
                (_listController.value - delay * 0.5).clamp(0.0, 1.0));
            return UserCard(
              user: user,
              animation: AlwaysStoppedAnimation(animValue),
              onEdit: () => _openDialog(user: user),
              onDelete: AuthService.currentUserId != user['id'].toString()
                  ? () => _confirmDelete(user)
                  : null,
            );
          },
        );
      },
    );
  }
}
