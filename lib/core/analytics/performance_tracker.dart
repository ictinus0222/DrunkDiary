import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';
import 'analytics_parameters.dart';

final performanceTrackerProvider = Provider<PerformanceTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return PerformanceTracker(analytics);
});

class PerformanceTracker {
  final AnalyticsService _analytics;

  PerformanceTracker(this._analytics);

  /// Measure the duration of a repository operation or any task.
  Future<T> trackDuration<T>({
    required String operationName,
    required Future<T> Function() action,
    Map<String, Object>? extraParams,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();

      await _analytics.logEvent(
        name: AnalyticsEvents.repositoryOperation,
        parameters: {
          AnalyticsParams.operationName: operationName,
          AnalyticsParams.durationMs: stopwatch.elapsedMilliseconds,
          AnalyticsParams.status: 'success',
          ...?extraParams,
        },
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      await _analytics.logFailure(
        operation: operationName,
        error: e,
        extraParams: {
          AnalyticsParams.durationMs: stopwatch.elapsedMilliseconds,
          ...?extraParams,
        },
      );
      rethrow;
    }
  }
}
