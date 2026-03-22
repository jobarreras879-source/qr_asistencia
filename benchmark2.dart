import 'dart:core';

void main() {
  final List<String> dates = List.generate(
    100000,
    (i) => '2023-10-15 14:30:00Z',
  );

  // Baseline String formatting vs String extraction for _formatDate

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateOpt(String? dateStr) {
    if (dateStr == null) return '';
    if (dateStr.length >= 10 && dateStr[4] == '-' && dateStr[7] == '-') {
      return '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}/${dateStr.substring(0, 4)}';
    }
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // Baseline String formatting vs String extraction for _formatTime
  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatTimeOpt(String? dateStr) {
    if (dateStr == null) return '';
    // Expected format: YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM:SS
    if (dateStr.length >= 16 &&
        dateStr[4] == '-' &&
        dateStr[7] == '-' &&
        dateStr[13] == ':') {
      return dateStr.substring(11, 16);
    }
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  final watch1 = Stopwatch()..start();
  for (final date in dates) {
    _formatDate(date);
    _formatTime(date);
  }
  watch1.stop();
  print('Original: ${watch1.elapsedMilliseconds} ms');

  final watch2 = Stopwatch()..start();
  for (final date in dates) {
    _formatDateOpt(date);
    _formatTimeOpt(date);
  }
  watch2.stop();
  print('Optimized: ${watch2.elapsedMilliseconds} ms');
}
