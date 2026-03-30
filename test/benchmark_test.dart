import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benchmark Map vs List Lookup', () {
    // Generate large list of projects
    final List<Map<String, dynamic>> proys = List.generate(
      10000,
      (index) => {'numero': index.toString(), 'nombre': 'Project $index'},
    );

    final targetId = '9999';

    // Baseline: Linear search
    final stopwatchList = Stopwatch()..start();
    Map<String, dynamic>? resultList;
    for (int i = 0; i < 1000; i++) {
      for (final proyecto in proys) {
        if (proyecto['numero']?.toString() == targetId) {
          resultList = proyecto;
          break;
        }
      }
    }
    stopwatchList.stop();
    print(
      'List lookup took: ${stopwatchList.elapsedMicroseconds} microseconds',
    );

    // Optimization: Map lookup
    final stopwatchMapConvert = Stopwatch()..start();
    final Map<String, Map<String, dynamic>> proysMap = {};
    for (final proyecto in proys) {
      proysMap[proyecto['numero']?.toString() ?? ''] = proyecto;
    }
    stopwatchMapConvert.stop();
    print(
      'Map conversion took: ${stopwatchMapConvert.elapsedMicroseconds} microseconds',
    );

    final stopwatchMap = Stopwatch()..start();
    Map<String, dynamic>? resultMap;
    for (int i = 0; i < 1000; i++) {
      resultMap = proysMap[targetId];
    }
    stopwatchMap.stop();
    print('Map lookup took: ${stopwatchMap.elapsedMicroseconds} microseconds');

    expect(resultList?['numero'], resultMap?['numero']);
  });
}
