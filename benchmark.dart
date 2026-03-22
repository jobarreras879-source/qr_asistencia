import 'dart:core';

String _formatDate(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final dt = DateTime.parse(dateStr);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

String _formatDateOptimized(String? dateStr) {
  if (dateStr == null) return '';
  // Expected format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS
  if (dateStr.length >= 10) {
    if (dateStr[4] == '-' && dateStr[7] == '-') {
      return '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}/${dateStr.substring(0, 4)}';
    }
  }
  return _formatDate(dateStr);
}

void main() {
  final List<String> dates = List.generate(
    100000,
    (i) => '2023-10-15 14:30:00Z',
  );

  final watch1 = Stopwatch()..start();
  for (final date in dates) {
    _formatDate(date);
  }
  watch1.stop();
  print('Original: ${watch1.elapsedMilliseconds} ms');

  final watch2 = Stopwatch()..start();
  for (final date in dates) {
    _formatDateOptimized(date);
  }
  watch2.stop();
  print('Optimized: ${watch2.elapsedMilliseconds} ms');
}
