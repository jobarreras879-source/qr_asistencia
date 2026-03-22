void main() async {
  print('Simulating Google Sheets API Benchmark');
  print('======================================');

  // Assume a network round trip latency of 300ms
  final latency = Duration(milliseconds: 300);
  final numRecords = 50;

  print('Number of records to sync: $numRecords');
  print('Estimated network latency per request: ${latency.inMilliseconds}ms\n');

  // N+1 approach
  final nPlusOneTime = latency * numRecords;
  print('N+1 approach (baseline):');
  print('- Makes $numRecords individual API requests.');
  print('- Estimated time: ${nPlusOneTime.inMilliseconds}ms (${nPlusOneTime.inSeconds} seconds)\n');

  // Batch approach
  final batchTime = latency; // O(1) request
  print('Batch approach (optimized):');
  print('- Makes 1 API request.');
  print('- Estimated time: ${batchTime.inMilliseconds}ms (${batchTime.inSeconds} seconds)\n');

  // Improvement
  final speedup = nPlusOneTime.inMilliseconds / batchTime.inMilliseconds;
  print('Improvement:');
  print('- ${speedup}x faster');
  print('- Saved ${nPlusOneTime.inMilliseconds - batchTime.inMilliseconds}ms');
}
