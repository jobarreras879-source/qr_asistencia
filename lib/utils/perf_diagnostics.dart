import 'package:flutter/foundation.dart';

class PerfDiagnostics {
  static final Stopwatch appStart = Stopwatch()..start();
  static int _nextTraceId = 1;

  static bool get enabled => kDebugMode || kProfileMode;

  static PerfTrace startTrace(
    String name, {
    Map<String, Object?> context = const {},
  }) {
    return PerfTrace._(name, _nextTraceId++, context);
  }

  static void log(
    String scope,
    String message, {
    Map<String, Object?> data = const {},
  }) {
    if (!enabled) return;

    final buffer = StringBuffer('[PERF][$scope] $message');
    if (data.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(_formatData(data));
    }
    debugPrint(buffer.toString());
  }

  static String _formatData(Map<String, Object?> data) {
    return data.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
  }
}

class PerfTrace {
  final String name;
  final int id;
  final Stopwatch _total = Stopwatch()..start();

  PerfTrace._(
    this.name,
    this.id,
    Map<String, Object?> context,
  ) {
    PerfDiagnostics.log(scope, 'START', data: context);
  }

  String get scope => '$name#$id';

  Future<T> measureAsync<T>(
    String step,
    Future<T> Function() action, {
    Map<String, Object?> data = const {},
  }) async {
    final stopwatch = Stopwatch()..start();
    PerfDiagnostics.log(scope, 'STEP_START $step', data: data);

    try {
      final result = await action();
      PerfDiagnostics.log(
        scope,
        'STEP_END $step',
        data: {
          ...data,
          'ms': stopwatch.elapsedMilliseconds,
        },
      );
      return result;
    } catch (error) {
      PerfDiagnostics.log(
        scope,
        'STEP_ERROR $step',
        data: {
          ...data,
          'ms': stopwatch.elapsedMilliseconds,
          'error': error.toString(),
        },
      );
      rethrow;
    }
  }

  void mark(
    String step, {
    Map<String, Object?> data = const {},
  }) {
    PerfDiagnostics.log(
      scope,
      step,
      data: {
        ...data,
        'msFromStart': _total.elapsedMilliseconds,
      },
    );
  }

  void finish({
    Map<String, Object?> data = const {},
  }) {
    PerfDiagnostics.log(
      scope,
      'END',
      data: {
        ...data,
        'totalMs': _total.elapsedMilliseconds,
      },
    );
  }
}
