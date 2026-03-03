import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Monitors and logs performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Starts timing an operation
  void startTimer(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  /// Stops timing an operation and logs the duration
  void stopTimer(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint('Warning: Timer "$operationName" was not started');
      }
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operationName);

    // Store metric
    _metrics.putIfAbsent(operationName, () => []).add(duration);

    // Log if duration is significant
    if (duration.inMilliseconds > 100) {
      developer.log(
        'Performance: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// Measures the execution time of a function
  Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      return await operation();
    } finally {
      stopTimer(operationName);
    }
  }

  /// Measures the execution time of a synchronous function
  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      return operation();
    } finally {
      stopTimer(operationName);
    }
  }

  /// Gets average duration for an operation
  Duration? getAverageDuration(String operationName) {
    final durations = _metrics[operationName];
    if (durations == null || durations.isEmpty) {
      return null;
    }

    final totalMicroseconds = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }

  /// Gets all metrics
  Map<String, Duration?> getAllMetrics() {
    return Map.fromEntries(
      _metrics.keys.map((key) => MapEntry(key, getAverageDuration(key))),
    );
  }

  /// Clears all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  /// Logs all metrics
  void logMetrics() {
    if (_metrics.isEmpty) {
      developer.log('No performance metrics recorded', name: 'PerformanceMonitor');
      return;
    }

    developer.log('Performance Metrics:', name: 'PerformanceMonitor');
    for (final entry in _metrics.entries) {
      final avg = getAverageDuration(entry.key);
      final count = entry.value.length;
      developer.log(
        '  ${entry.key}: avg ${avg?.inMilliseconds}ms (${count} samples)',
        name: 'PerformanceMonitor',
      );
    }
  }
}

/// Extension for easy performance monitoring
extension PerformanceMonitorExtension on Future {
  Future<T> withPerformanceMonitoring<T>(String operationName) async {
    return PerformanceMonitor().measure(operationName, () async => await this as T);
  }
}
