import 'dart:async';

// Mock function to simulate network latency for a single row insertion
Future<bool> appendAttendanceRowMock() async {
  await Future.delayed(Duration(milliseconds: 100)); // Simulate 100ms network round-trip
  return true;
}

// Mock function to simulate network latency for a batch insertion
Future<bool> appendAttendanceRowsMock(int rowCount) async {
  // Batch request might take slightly longer, but much less than N individual requests
  await Future.delayed(Duration(milliseconds: 100 + (rowCount * 2)));
  return true;
}

void main() async {
  print('--- Performance Benchmark: N+1 vs Batch API Calls ---');

  int numRows = 50;
  print('Syncing ${numRows} rows...');

  // Baseline: N+1 API Calls
  final stopwatchBaseline = Stopwatch()..start();
  int successCountBaseline = 0;
  for (int i = 0; i < numRows; i++) {
    bool success = await appendAttendanceRowMock();
    if (success) successCountBaseline++;
  }
  stopwatchBaseline.stop();
  final baselineTime = stopwatchBaseline.elapsedMilliseconds;
  print('Baseline (N+1 Calls): ${baselineTime}ms');

  // Improvement: Batch API Call
  final stopwatchBatch = Stopwatch()..start();
  bool successBatch = await appendAttendanceRowsMock(numRows);
  int successCountBatch = successBatch ? numRows : 0;
  stopwatchBatch.stop();
  final batchTime = stopwatchBatch.elapsedMilliseconds;
  print('Batch Call: ${batchTime}ms');

  final improvement = baselineTime - batchTime;
  final percentage = ((improvement / baselineTime) * 100).toStringAsFixed(2);

  print('--- Results ---');
  print('Speedup: ${improvement}ms (${percentage}% faster)');
}
