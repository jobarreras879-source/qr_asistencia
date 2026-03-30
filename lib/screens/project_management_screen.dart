import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';

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

  void _showProjectDialog({Map<String, dynamic>? project}) {
    final bool isEditing = project != null;
    final numController = TextEditingController(text: project?['numero'] ?? '');
    final nameController = TextEditingController(
      text: project?['nombre'] ?? '',
    );
    final clientController = TextEditingController(
      text: project?['cliente'] ?? '',
    );
    final ocController = TextEditingController(text: project?['oc'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.dialogDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing
                          ? Icons.edit_rounded
                          : Icons.add_business_rounded,
                      color: AppTheme.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'NÚMERO DE PROYECTO',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: AppTheme.inputDecoration(
                    hint: 'Ej: 105',
                    prefixIcon: Icons.numbers_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NOMBRE DEL PROYECTO',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: AppTheme.inputDecoration(
                    hint: 'Nombre descriptivo',
                    prefixIcon: Icons.badge_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CLIENTE (Opcional)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: clientController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: AppTheme.inputDecoration(
                    hint: 'Ej: PepsiCo',
                    prefixIcon: Icons.business_center_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ORDEN DE COMPRA / OC (Opcional)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ocController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: AppTheme.inputDecoration(
                    hint: 'Ej: M411',
                    prefixIcon: Icons.receipt_long_rounded,
                  ),
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
                          final num = numController.text.trim();
                          final name = nameController.text.trim();
                          final cliente = clientController.text.trim();
                          final oc = ocController.text.trim();

                          if (num.isEmpty || name.isEmpty) return;

                          String? error;
                          if (isEditing) {
                            error = await ProjectService.editarProyecto(
                              project['numero'],
                              num,
                              name,
                              cliente,
                              oc,
                            );
                          } else {
                            error = await ProjectService.crearProyecto(
                              num,
                              name,
                              cliente,
                              oc,
                            );
                          }

                          if (!mounted) return;
                          if (error == null) {
                            Navigator.pop(context);
                            _loadProjects();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Proyecto actualizado'
                                      : 'Proyecto creado',
                                ),
                                backgroundColor: AppTheme.success,
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
    );
  }

  void _confirmDelete(String numero) {
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
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 48,
              ),
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
                      onPressed: () => Navigator.pop(context),
                      style: AppTheme.secondaryButton,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final error = await ProjectService.eliminarProyecto(
                          numero,
                        );
                        if (!mounted) return;
                        if (error == null) {
                          Navigator.pop(context);
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          color: AppTheme.accent,
                        ),
                      )
                    : _projects.isEmpty
                    ? _buildEmptyState()
                    : _buildProjectList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProjectDialog(),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.glassDecoration.copyWith(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proyectos',
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
          const Spacer(),
          IconButton(
            onPressed: _loadProjects,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
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
          Icon(
            Icons.business_center_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay proyectos',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildProjectList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            final double delay = (index * 0.1).clamp(0, 1.0);
            final double animValue = Curves.easeOutCubic.transform(
              (_listController.value - delay * 0.5).clamp(0, 1.0),
            );

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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      project['numero'] ?? '?',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['nombre'] ?? 'Sin nombre',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ID: ${project['numero']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showProjectDialog(project: project),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(project['numero']),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
