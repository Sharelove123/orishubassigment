import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static List<HealthDataAccess> get _permissions =>
      _types.map((_) => HealthDataAccess.READ).toList();

  /// Request authorization to access health data
  Future<bool> requestAuthorization() async {
    try {
      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return authorized;
    } catch (e) {
      debugPrint('Health authorization error: $e');
      return false;
    }
  }

  /// Check if health data access is authorized
  Future<bool> hasPermissions() async {
    try {
      final authorized = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      return authorized ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fetch health data since [since] timestamp
  Future<Map<String, dynamic>> fetchHealthData({DateTime? since}) async {
    final now = DateTime.now();
    final startTime = since ?? DateTime(now.year, now.month, now.day);

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: startTime,
        endTime: now,
      );

      return _formatHealthData(healthData, now);
    } catch (e) {
      debugPrint('Health data fetch error: $e');
      return _emptyPayload();
    }
  }

  Map<String, dynamic> _formatHealthData(
      List<HealthDataPoint> data, DateTime now) {
    final nowIso = now.toUtc().toIso8601String();
    final startOfDay =
        DateTime.utc(now.year, now.month, now.day).toIso8601String();

    // Aggregate steps
    double totalSteps = 0;
    for (final point in data) {
      if (point.type == HealthDataType.STEPS) {
        totalSteps += (point.value as NumericHealthValue).numericValue;
      }
    }

    // Get latest heart rate readings
    final heartRates = data
        .where((p) => p.type == HealthDataType.HEART_RATE)
        .map((p) => {
              "type": "HEART_RATE",
              "unit": "BEATS_PER_MINUTE",
              "value":
                  (p.value as NumericHealthValue).numericValue.toStringAsFixed(0),
              "end_time": p.dateTo.toUtc().toIso8601String(),
              "platform": "android",
              "start_time": p.dateFrom.toUtc().toIso8601String(),
              "source_name": "health_connect"
            })
        .toList();

    // Get latest weight
    final weights = data
        .where((p) => p.type == HealthDataType.WEIGHT)
        .map((p) => {
              "type": "WEIGHT",
              "unit": "KILOGRAMS",
              "value":
                  (p.value as NumericHealthValue).numericValue.toStringAsFixed(1),
              "end_time": p.dateTo.toUtc().toIso8601String(),
              "platform": "android",
              "start_time": p.dateFrom.toUtc().toIso8601String(),
              "source_name": "health_connect"
            })
        .toList();

    // Aggregate calories
    double totalCalories = 0;
    for (final point in data) {
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        totalCalories += (point.value as NumericHealthValue).numericValue;
      }
    }

    // Get sleep data
    final sleepData = data
        .where((p) => p.type == HealthDataType.SLEEP_ASLEEP)
        .map((p) => {
              "type": "SLEEP_ASLEEP",
              "unit": "MINUTES",
              "value": p.dateTo.difference(p.dateFrom).inMinutes.toString(),
              "end_time": p.dateTo.toUtc().toIso8601String(),
              "platform": "android",
              "start_time": p.dateFrom.toUtc().toIso8601String(),
              "source_name": "health_connect"
            })
        .toList();

    return {
      "sleep": sleepData,
      "steps": [
        if (totalSteps > 0)
          {
            "type": "STEPS",
            "unit": "COUNT",
            "value": totalSteps.toStringAsFixed(0),
            "end_time": nowIso,
            "platform": "android",
            "start_time": startOfDay,
            "source_name": "health_connect"
          }
      ],
      "weight": weights,
      "calories": [
        if (totalCalories > 0)
          {
            "type": "CALORIES_EXPENDED",
            "unit": "KILOCALORIES",
            "value": totalCalories.toStringAsFixed(1),
            "end_time": nowIso,
            "platform": "android",
            "start_time": startOfDay,
            "source_name": "health_connect"
          }
      ],
      "heart_rate": heartRates,
    };
  }

  Map<String, dynamic> _emptyPayload() {
    return {
      "sleep": [],
      "steps": [],
      "weight": [],
      "calories": [],
      "heart_rate": [],
    };
  }
}
