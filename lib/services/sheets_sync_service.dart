import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_drive_service.dart';

class SheetsSyncResult {
  final int successCount;
  final int errorCount;

  const SheetsSyncResult({
    required this.successCount,
    required this.errorCount,
  });
}

class SheetsSyncService {
  static final _supabase = Supabase.instance.client;

  static Future<SheetsSyncResult> exportHistory(String spreadsheetId) async {
    try {
      final data = await _supabase
          .from('registros')
          .select()
          .order('fecha_hora', ascending: true);

      var successCount = 0;
      var errorCount = 0;

      for (final row in List<Map<String, dynamic>>.from(data)) {
        final success = await GoogleDriveService.appendAttendanceRow(
          spreadsheetId,
          row,
        );

        if (success) {
          successCount++;
        } else {
          errorCount++;
        }
      }

      return SheetsSyncResult(
        successCount: successCount,
        errorCount: errorCount,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('SheetsSyncService.exportHistory error: $error');
        debugPrintStack(stackTrace: stack);
      }
      rethrow;
    }
  }
}
