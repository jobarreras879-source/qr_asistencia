import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';

class ProjectDialog extends StatefulWidget {
  final Map<String, dynamic>? project;

  const ProjectDialog({super.key, this.project});

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late TextEditingController _numController;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _numController = TextEditingController(
      text: widget.project?['numero'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.project?['nombre'] ?? '',
    );
  }

  @override
  void dispose() {
    _numController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final num = _numController.text.trim();
    final name = _nameController.text.trim();

    if (num.isEmpty || name.isEmpty) return;

    setState(() => _isSaving = true);
    String? error;
    if (widget.project != null) {
      error = await ProjectService.editarProyecto(
        widget.project!['numero'],
        num,
        name,
      );
    } else {
      error = await ProjectService.crearProyecto(num, name);
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
    final isEditing = widget.project != null;

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
              _buildLabel('NÚMERO DE PROYECTO'),
              const SizedBox(height: 8),
              TextField(
                controller: _numController,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: AppTheme.inputDecoration(
                  hint: 'Ej: 105',
                  prefixIcon: Icons.numbers_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('NOMBRE DEL PROYECTO'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: AppTheme.inputDecoration(
                  hint: 'Nombre descriptivo',
                  prefixIcon: Icons.badge_rounded,
                ),
              ),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_business_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              isEditing
                  ? 'Actualiza los datos del proyecto'
                  : 'Crea un nuevo frente de trabajo',
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
                    widget.project != null ? 'Guardar' : 'Crear',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
