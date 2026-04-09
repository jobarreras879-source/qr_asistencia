import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class DriveLinkedState extends StatelessWidget {
  final bool isCreating;
  final String? linkedEmail;
  final String? selectedFolderId;
  final String? selectedFolderName;
  final List<Map<String, String>> folders;
  final VoidCallback onUnlink;
  final VoidCallback onCreateFolder;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, String>> onSelectFolder;

  const DriveLinkedState({
    super.key,
    required this.isCreating,
    required this.linkedEmail,
    required this.selectedFolderId,
    required this.selectedFolderName,
    required this.folders,
    required this.onUnlink,
    required this.onCreateFolder,
    required this.onRefresh,
    required this.onSelectFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.elevatedCardDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: Color(0xFF4285F4),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta vinculada (backend)',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linkedEmail ?? 'Cuenta desconocida',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off_rounded, color: AppTheme.error),
                onPressed: onUnlink,
                tooltip: 'Desvincular Drive',
              ),
            ],
          ),
        ),
        if (selectedFolderId != null) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carpeta activa:',
                        style: GoogleFonts.inter(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        selectedFolderName ?? 'Carpeta desconocida',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: onCreateFolder,
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
                  child: folders.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron carpetas',
                            style: GoogleFonts.inter(color: AppTheme.textMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: onRefresh,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: folders.length,
                            itemBuilder: (context, index) {
                              final folder = folders[index];
                              final isSelected = folder['id'] == selectedFolderId;

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
                                    folder['name'] ?? 'Sin nombre',
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
                                  onTap: () => onSelectFolder(folder),
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
