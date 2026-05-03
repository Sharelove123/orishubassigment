import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final Health _health = Health();
  bool _configured = false;
  bool _historyAuthorizationRequested = false;

  static const List<HealthDataType> _permissionTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.BODY_MASS_INDEX,
  ];

  /// Steps + calories only — heart rate is fetched separately with a longer window
  static const List<HealthDataType> _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static const Duration _heartRateLookback = Duration(hours: 24);
  static const Duration _weightLookback = Duration(days: 365);
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
      if (authorized) {
        await _requestHistoryAuthorizationIfAvailable();
      }
      return authorized;
    } catch (e) {
      debugPrint('[HealthService] Authorization error: $e');
      return false;
    }
  }

  Future<void> _requestHistoryAuthorizationIfAvailable() async {
    try {
      final available = await _health.isHealthDataHistoryAvailable();
      if (!available) {
        debugPrint('[HealthService] Health data history is not available');
        return;
      }

      final alreadyAuthorized = await _health.isHealthDataHistoryAuthorized();
      if (alreadyAuthorized) {
        return;
      }

      if (_historyAuthorizationRequested) {
        return;
      }
      _historyAuthorizationRequested = true;

      final granted = await _health.requestHealthDataHistoryAuthorization();
      debugPrint('[HealthService] Health data history authorization: $granted');
    } catch (e) {
      debugPrint('[HealthService] History authorization error: $e');
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
    final heartRateStartTime = now.subtract(_heartRateLookback);
    final weightStartTime = now.subtract(_weightLookback);
    final sleepStartTime = now.subtract(_sleepLookback);

    debugPrint(
      '[HealthService] Fetching activity data from $activityStartTime to $now',
    );
    debugPrint(
      '[HealthService] Fetching heart rate from $heartRateStartTime to $now',
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
      var hasPerms = await hasPermissions();
      if (!hasPerms) {
        debugPrint('[HealthService] No permissions - requesting authorization');
        final granted = await requestAuthorization();
        if (!granted) {
          debugPrint('[HealthService] Authorization denied - requesting again after delay');
          // Try requesting one more time after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          final retryGranted = await requestAuthorization();
          if (!retryGranted) {
            debugPrint('[HealthService] Authorization denied after retry - returning empty');
            return _emptyPayload();
          }
          hasPerms = true;
        } else {
          hasPerms = true;
        }
      }
      await _requestHistoryAuthorizationIfAvailable();

      final healthData = <HealthDataPoint>[
        ...await _getHealthData(
          types: _activityTypes,
          startTime: activityStartTime,
          endTime: now,
          label: 'activity',
        ),
        // Heart rate fetched separately with 24h lookback
        ...await _getHealthData(
          types: const [HealthDataType.HEART_RATE],
          startTime: heartRateStartTime,
          endTime: now,
          label: 'heart_rate',
        ),
        // Weight + BMI fetched with 365-day lookback
        ...await _getHealthData(
          types: const [HealthDataType.WEIGHT, HealthDataType.BODY_MASS_INDEX],
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
      debugPrint('[HealthService] Requesting $label data from $startTime to $endTime');
      debugPrint('[HealthService] Types requested: ${types.map((t) => t.name).join(", ")}');
      
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: endTime,
      );
      
      debugPrint('[HealthService] $label: Got ${points.length} points');
      if (points.isEmpty) {
        debugPrint('[HealthService] ⚠️ WARNING: No $label data found!');
      } else {
        for (final p in points.take(3)) {
          debugPrint('[HealthService] $label sample: ${p.type} = ${p.value} (${p.dateFrom} -> ${p.dateTo})');
        }
      }
      
      return points;
    } catch (e) {
      debugPrint('[HealthService] ❌ $label fetch error: $e');
      debugPrint('[HealthService] Stack trace: ${StackTrace.current}');
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

    // Get latest heart rate readings (24h lookback)
    final heartRates =
        data.where((p) => p.type == HealthDataType.HEART_RATE).toList()
          ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    debugPrint('[HealthService] Heart rate points found: ${heartRates.length}');
    if (heartRates.isNotEmpty) {
      debugPrint('[HealthService] Latest HR: ${_numericValue(heartRates.last)} bpm at ${heartRates.last.dateTo}');
    } else {
      debugPrint('[HealthService] ⚠️ No heart rate data in last 24 hours');
    }

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

    // Get latest weight (also check BODY_MASS_INDEX as fallback)
    final weightPoints =
        data.where((p) => p.type == HealthDataType.WEIGHT || p.type == HealthDataType.BODY_MASS_INDEX).toList()
          ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
    debugPrint('[HealthService] Weight points found: ${weightPoints.length}');
    if (weightPoints.isNotEmpty) {
      debugPrint('[HealthService] Latest weight: ${_numericValue(weightPoints.first)} at ${weightPoints.first.dateTo}');
    } else {
      debugPrint('[HealthService] ⚠️ No weight data in last 365 days');
    }

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
