import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers.dart';

class PermissionsState {
  final bool healthGranted;
  final bool locationGranted;
  final bool cameraGranted;
  final bool microphoneGranted;
  final bool allRequiredGranted;

  PermissionsState({
    this.healthGranted = false,
    this.locationGranted = false,
    this.cameraGranted = false,
    this.microphoneGranted = false,
  }) : allRequiredGranted = healthGranted && locationGranted;

  PermissionsState copyWith({
    bool? healthGranted,
    bool? locationGranted,
    bool? cameraGranted,
    bool? microphoneGranted,
  }) {
    return PermissionsState(
      healthGranted: healthGranted ?? this.healthGranted,
      locationGranted: locationGranted ?? this.locationGranted,
      cameraGranted: cameraGranted ?? this.cameraGranted,
      microphoneGranted: microphoneGranted ?? this.microphoneGranted,
    );
  }
}

class PermissionsController extends Notifier<PermissionsState> {
  @override
  PermissionsState build() => PermissionsState();

  Future<void> checkAllPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    final health = await healthService.hasPermissions();
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
    final granted = await healthService.requestAuthorization();
    state = state.copyWith(healthGranted: granted);
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
