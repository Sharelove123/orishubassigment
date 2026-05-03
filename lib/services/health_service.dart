import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final Health _health = Health();
  bool _configured = false;

  static const List<HealthDataType> _permissionTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_SESSION,
  ];

  static const List<HealthDataType> _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static const Duration _weightLookback = Duration(days: 30);
  static const Duration _sleepLookback = Duration(days: 7);

  static List<HealthDataAccess> get _permissions =>
      _permissionTypes.map((_) => HealthDataAccess.READ).toList();

  /// Configure the health plugin (must be called before any other method)
  Future<void> _ensureConfigured() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
      debugPrint('[HealthService] Configured successfully');
    }
  }

  /// Check if Health Connect is available on this device
  Future<bool> isHealthConnectAvailable() async {
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      debugPrint('[HealthService] Health Connect SDK status: $status');
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('[HealthService] Health Connect availability check error: $e');
      return false;
    }
  }

  /// Request authorization to access health data
  Future<bool> requestAuthorization() async {
    try {
      await _ensureConfigured();

      // Check Health Connect availability first
      final available = await isHealthConnectAvailable();
      if (!available) {
        debugPrint(
          '[HealthService] Health Connect not available - opening Play Store',
        );
        await _health.installHealthConnect();
        return false;
      }

      final authorized = await _health.requestAuthorization(
        _permissionTypes,
        permissions: _permissions,
      );
      debugPrint('[HealthService] Authorization result: $authorized');
      return authorized;
    } catch (e) {
      debugPrint('[HealthService] Authorization error: $e');
      return false;
    }
  }

  /// Check if health data access is authorized
  Future<bool> hasPermissions() async {
    try {
      await _ensureConfigured();
      final authorized = await _health.hasPermissions(
        _permissionTypes,
        permissions: _permissions,
      );
      debugPrint('[HealthService] hasPermissions: $authorized');
      return authorized ?? false;
    } catch (e) {
      debugPrint('[HealthService] hasPermissions error: $e');
      return false;
    }
  }

  /// Fetch health data since [since] timestamp
  Future<Map<String, dynamic>> fetchHealthData({DateTime? since}) async {
    final now = DateTime.now();
    final activityStartTime = since ?? DateTime(now.year, now.month, now.day);
    final weightStartTime = now.subtract(_weightLookback);
    final sleepStartTime = now.subtract(_sleepLookback);

    debugPrint(
      '[HealthService] Fetching activity data from $activityStartTime to $now',
    );
    debugPrint(
      '[HealthService] Fetching weight data from $weightStartTime to $now',
    );
    debugPrint(
      '[HealthService] Fetching sleep data from $sleepStartTime to $now',
    );

    try {
      await _ensureConfigured();

      // Check permissions first
      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        debugPrint('[HealthService] No permissions - requesting authorization');
        final granted = await requestAuthorization();
        if (!granted) {
          debugPrint('[HealthService] Authorization denied - returning empty');
          return _emptyPayload();
        }
      }

      final healthData = <HealthDataPoint>[
        ...await _getHealthData(
          types: _activityTypes,
          startTime: activityStartTime,
          endTime: now,
          label: 'activity',
        ),
        ...await _getHealthData(
          types: const [HealthDataType.WEIGHT],
          startTime: weightStartTime,
          endTime: now,
          label: 'weight',
        ),
        ...await _getHealthData(
          types: const [HealthDataType.SLEEP_SESSION],
          startTime: sleepStartTime,
          endTime: now,
          label: 'sleep',
        ),
      ];

      debugPrint('[HealthService] Got ${healthData.length} data points');
      for (final point in healthData) {
        debugPrint(
          '[HealthService]   ${point.type}: ${point.value} (${point.dateFrom} -> ${point.dateTo})',
        );
      }

      return _formatHealthData(healthData, now);
    } catch (e) {
      debugPrint('[HealthService] Fetch error: $e');
      return _emptyPayload();
    }
  }

  Future<List<HealthDataPoint>> _getHealthData({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    required String label,
  }) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: endTime,
      );
      debugPrint('[HealthService] $label points: ${points.length}');
      return points;
    } catch (e) {
      debugPrint('[HealthService] $label fetch error: $e');
      return [];
    }
  }

  Map<String, dynamic> _formatHealthData(
    List<HealthDataPoint> data,
    DateTime now,
  ) {
    final nowIso = now.toUtc().toIso8601String();
    final startOfDay = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).toIso8601String();

    // Aggregate steps
    double totalSteps = 0;
    for (final point in data) {
      if (point.type == HealthDataType.STEPS) {
        totalSteps += _numericValue(point);
      }
    }
    debugPrint('[HealthService] Total steps: $totalSteps');

    // Get latest heart rate readings
    final heartRates =
        data.where((p) => p.type == HealthDataType.HEART_RATE).toList()
          ..sort((a, b) => a.dateTo.compareTo(b.dateTo));

    final heartRateData = heartRates
        .map(
          (p) => {
            "type": "HEART_RATE",
            "unit": "BEATS_PER_MINUTE",
            "value": _numericValue(p).toStringAsFixed(0),
            "end_time": p.dateTo.toUtc().toIso8601String(),
            "platform": "android",
            "start_time": p.dateFrom.toUtc().toIso8601String(),
            "source_name": _sourceName(p),
          },
        )
        .toList();

    // Get latest weight
    final weightPoints =
        data.where((p) => p.type == HealthDataType.WEIGHT).toList()
          ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

    final weights = weightPoints
        .map(
          (p) => {
            "type": "WEIGHT",
            "unit": "KILOGRAMS",
            "value": _numericValue(p).toStringAsFixed(1),
            "end_time": p.dateTo.toUtc().toIso8601String(),
            "platform": "android",
            "start_time": p.dateFrom.toUtc().toIso8601String(),
            "source_name": _sourceName(p),
          },
        )
        .toList();

    // Aggregate calories
    double activeCalories = 0;
    double totalCalories = 0;
    for (final point in data) {
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        activeCalories += _numericValue(point);
      }
      if (point.type == HealthDataType.TOTAL_CALORIES_BURNED) {
        totalCalories += _numericValue(point);
      }
    }
    final calories = activeCalories > 0 ? activeCalories : totalCalories;
    debugPrint('[HealthService] Active calories: $activeCalories');
    debugPrint('[HealthService] Total calories: $totalCalories');

    // Get sleep data
    final sleepPoints =
        data.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList()
          ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

    final sleepData = sleepPoints
        .map(
          (p) => {
            "type": "SLEEP_ASLEEP",
            "unit": "MINUTES",
            "value": _numericValue(p).toStringAsFixed(0),
            "end_time": p.dateTo.toUtc().toIso8601String(),
            "platform": "android",
            "start_time": p.dateFrom.toUtc().toIso8601String(),
            "source_name": _sourceName(p),
          },
        )
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
            "source_name": "health_connect",
          },
      ],
      "weight": weights,
      "calories": [
        if (calories > 0)
          {
            "type": "CALORIES_EXPENDED",
            "unit": "KILOCALORIES",
            "value": calories.toStringAsFixed(1),
            "end_time": nowIso,
            "platform": "android",
            "start_time": startOfDay,
            "source_name": "health_connect",
          },
      ],
      "heart_rate": heartRateData,
    };
  }

  double _numericValue(HealthDataPoint point) =>
      (point.value as NumericHealthValue).numericValue.toDouble();

  String _sourceName(HealthDataPoint point) =>
      point.sourceName.isNotEmpty ? point.sourceName : "health_connect";

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
