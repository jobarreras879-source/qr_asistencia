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
  late TextEditingController _clientController;
  late TextEditingController _ocController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _numController = TextEditingController(text: widget.project?['numero'] ?? '');
    _nameController = TextEditingController(text: widget.project?['nombre'] ?? '');
    _clientController = TextEditingController(text: widget.project?['cliente'] ?? '');
    _ocController = TextEditingController(text: widget.project?['oc'] ?? '');
  }

  @override
  void dispose() {
    _numController.dispose();
    _nameController.dispose();
    _clientController.dispose();
    _ocController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final num = _numController.text.trim();
    final name = _nameController.text.trim();
    final cliente = _clientController.text.trim();
    final oc = _ocController.text.trim();

    if (num.isEmpty || name.isEmpty) return;

    setState(() => _isSaving = true);
    String? error;
    if (widget.project != null) {
      error = await ProjectService.editarProyecto(
        widget.project!['numero'],
        num,
        name,
        cliente,
        oc,
      );
    } else {
      error = await ProjectService.crearProyecto(num, name, cliente, oc);
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
    final isEditing = widget.project != null;

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
              _buildLabel('NÚMERO DE PROYECTO'),
              const SizedBox(height: 8),
              TextField(
                controller: _numController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
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
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppTheme.inputDecoration(
                  hint: 'Nombre descriptivo',
                  prefixIcon: Icons.badge_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('CLIENTE (Opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _clientController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppTheme.inputDecoration(
                  hint: 'Ej: PepsiCo',
                  prefixIcon: Icons.business_center_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('ORDEN DE COMPRA / OC (Opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _ocController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: AppTheme.inputDecoration(
                  hint: 'Ej: M411',
                  prefixIcon: Icons.receipt_long_rounded,
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
        Icon(
          isEditing ? Icons.edit_rounded : Icons.add_business_rounded,
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
                : Text(widget.project != null ? 'Guardar' : 'Crear'),
          ),
        ),
      ],
    );
  }
}
