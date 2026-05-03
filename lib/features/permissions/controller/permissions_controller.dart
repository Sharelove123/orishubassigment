import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers.dart';

class PermissionsState {
  final bool healthGranted;
  final bool locationGranted;
  final bool cameraGranted;
  final bool microphoneGranted;
  final bool allRequiredGranted;
  final String? healthError;

  PermissionsState({
    this.healthGranted = false,
    this.locationGranted = false,
    this.cameraGranted = false,
    this.microphoneGranted = false,
    this.healthError,
  }) : allRequiredGranted = healthGranted && locationGranted;

  PermissionsState copyWith({
    bool? healthGranted,
    bool? locationGranted,
    bool? cameraGranted,
    bool? microphoneGranted,
    String? healthError,
  }) {
    return PermissionsState(
      healthGranted: healthGranted ?? this.healthGranted,
      locationGranted: locationGranted ?? this.locationGranted,
      cameraGranted: cameraGranted ?? this.cameraGranted,
      microphoneGranted: microphoneGranted ?? this.microphoneGranted,
      healthError: healthError,
    );
  }
}

class PermissionsController extends Notifier<PermissionsState> {
  @override
  PermissionsState build() => PermissionsState();

  Future<void> checkAllPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    // On Android, hasPermissions() can return null (unknown).
    // Treat null as potentially granted to avoid wrongly blocking the user.
    final healthPerm = await healthService.hasPermissionsNullable();
    final activityPerm = await Permission.activityRecognition.isGranted;
    // null = unknown on Android, treat as granted to avoid blocking
    final health = (healthPerm ?? true) && activityPerm;
    final location = await locationService.hasPermission();
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;

    state = PermissionsState(
      healthGranted: health,
      locationGranted: location,
      cameraGranted: camera,
      microphoneGranted: mic,
    );
  }

  Future<void> requestHealth() async {
    final healthService = ref.read(healthServiceProvider);

    final activityRecognition = await Permission.activityRecognition.request();
    if (!activityRecognition.isGranted) {
      state = state.copyWith(
        healthGranted: false,
        healthError:
            'Activity recognition permission is needed to read fitness data.',
      );
      return;
    }

    // Check if Health Connect is available first
    final available = await healthService.isHealthConnectAvailable();
    if (!available) {
      state = state.copyWith(
        healthGranted: false,
        healthError: 'Health Connect is not installed. Opening Play Store...',
      );
      // This will trigger the Play Store to install Health Connect
      await healthService.requestAuthorization();
      return;
    }

    final granted = await healthService.requestAuthorization();
    state = state.copyWith(
      healthGranted: granted,
      healthError: granted
          ? null
          : 'Permission denied. Please allow in Health Connect settings.',
    );
  }

  Future<void> requestLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final granted = await locationService.requestPermission();
    state = state.copyWith(locationGranted: granted);
  }

  Future<void> requestCamera() async {
    final status = await Permission.camera.request();
    state = state.copyWith(cameraGranted: status.isGranted);
  }

  Future<void> requestMicrophone() async {
    final status = await Permission.microphone.request();
    state = state.copyWith(microphoneGranted: status.isGranted);
  }
}

final permissionsControllerProvider =
    NotifierProvider<PermissionsController, PermissionsState>(() {
      return PermissionsController();
    });
