import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/project_dialog.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await ProjectService.getProyectos();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
    _listController.forward(from: 0);
  }

  void _openDialog({Map<String, dynamic>? project}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ProjectDialog(project: project),
    );
    if (result == true && mounted) {
      _loadProjects();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              project != null ? 'Proyecto actualizado' : 'Proyecto creado'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _confirmDelete(String numero) {
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
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                '¿Eliminar Proyecto?',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción no se puede deshacer. Se eliminará el proyecto $numero.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
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
                        final error =
                            await ProjectService.eliminarProyecto(numero);
                        if (!mounted) return;
                        if (error == null) {
                          _loadProjects();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proyecto eliminado'),
                              backgroundColor: AppTheme.error,
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
                        child:
                            CircularProgressIndicator(color: AppTheme.accent))
                    : _projects.isEmpty
                        ? _buildEmptyState()
                        : _buildProjectList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        label: const Text('Nuevo Proyecto'),
        icon: const Icon(Icons.add_rounded),
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
                    'Gestion de proyectos',
                    style: GoogleFonts.ibmPlexSerif(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra catalogos y frentes de trabajo.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadProjects,
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
          Icon(Icons.business_center_outlined,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No hay proyectos',
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

  Widget _buildProjectList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final delay = (index * 0.1).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _listController,
          builder: (context, _) {
            final animValue = Curves.easeOutCubic.transform(
                (_listController.value - delay * 0.5).clamp(0.0, 1.0));
            return ProjectCard(
              project: project,
              animation: AlwaysStoppedAnimation(animValue),
              onEdit: () => _openDialog(project: project),
              onDelete: () => _confirmDelete(project['numero']),
            );
          },
        );
      },
    );
  }
}
