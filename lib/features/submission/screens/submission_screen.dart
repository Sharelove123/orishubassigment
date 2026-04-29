import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../controller/submission_controller.dart';
import '../../../core/theme.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  // Device Info
  final _deviceIdController = TextEditingController(text: '123456');

  // Activity
  final _stepsController = TextEditingController(text: '11178');
  final _caloriesController = TextEditingController(text: '487.3');

  // Body Metrics
  final _weightController = TextEditingController(text: '72.4');
  final _heartRateController = TextEditingController(text: '78');

  // Location
  final _latController = TextEditingController(text: '18.2915625');
  final _longController = TextEditingController(text: '79.4695052');
  final _accuracyController = TextEditingController(text: '128.9');
  final _altitudeController = TextEditingController(text: '181.4');
  final _speedController = TextEditingController(text: '0');

  @override
  void dispose() {
    _deviceIdController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _latController.dispose();
    _longController.dispose();
    _accuracyController.dispose();
    _altitudeController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day).toIso8601String();
    final nowIso = now.toIso8601String();

    return {
      "sleep": [],
      "steps": [
        {
          "type": "STEPS",
          "unit": "COUNT",
          "value": _stepsController.text,
          "end_time": nowIso,
          "platform": "android",
          "start_time": startOfDay,
          "source_name": "health_connect"
        }
      ],
      "weight": [
        {
          "type": "WEIGHT",
          "unit": "KILOGRAMS",
          "value": _weightController.text,
          "end_time": nowIso,
          "platform": "android",
          "start_time": nowIso,
          "source_name": "health_connect"
        }
      ],
      "calories": [
        {
          "type": "CALORIES_EXPENDED",
          "unit": "KILOCALORIES",
          "value": _caloriesController.text,
          "end_time": nowIso,
          "platform": "android",
          "start_time": startOfDay,
          "source_name": "health_connect"
        }
      ],
      "location": [
        {
          "speed": double.tryParse(_speedController.text) ?? 0.0,
          "accuracy": double.tryParse(_accuracyController.text) ?? 0.0,
          "altitude": double.tryParse(_altitudeController.text) ?? 0.0,
          "latitude": double.tryParse(_latController.text) ?? 0.0,
          "platform": "android",
          "longitude": double.tryParse(_longController.text) ?? 0.0,
          "timestamp": nowIso
        }
      ],
      "heart_rate": [
        {
          "type": "HEART_RATE",
          "unit": "BEATS_PER_MINUTE",
          "value": _heartRateController.text,
          "end_time": nowIso,
          "platform": "android",
          "start_time": nowIso,
          "source_name": "health_connect"
        }
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polso Health Data', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: _buildBanner(),
            ),
            const SizedBox(height: 32),
            _buildInputSection('Device Configuration', [
              _buildTextField(_deviceIdController, 'Device ID', Icons.devices_other),
            ]),
            const SizedBox(height: 24),
            _buildInputSection('Activity & Energy', [
              Row(
                children: [
                  Expanded(child: _buildTextField(_stepsController, 'Steps', Icons.directions_run, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_caloriesController, 'Calories', Icons.local_fire_department, keyboardType: TextInputType.number)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            _buildInputSection('Vitals & Metrics', [
              Row(
                children: [
                  Expanded(child: _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_heartRateController, 'Heart Rate (bpm)', Icons.favorite_border, keyboardType: TextInputType.number)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            _buildInputSection('Positioning', [
              Row(
                children: [
                  Expanded(child: _buildTextField(_latController, 'Latitude', Icons.map_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_longController, 'Longitude', Icons.map_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_accuracyController, 'Accuracy', Icons.gps_fixed, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_altitudeController, 'Altitude', Icons.height, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_speedController, 'Speed', Icons.speed, keyboardType: TextInputType.number),
            ]),
            const SizedBox(height: 40),
            if (state.resultMessage != null)
              FadeInUp(child: _buildStatusMessage(state)),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        ref.read(submissionControllerProvider.notifier).submitData(
                              _buildPayload(),
                              deviceId: _deviceIdController.text,
                            );
                      },
                icon: state.isSubmitting ? const SizedBox.shrink() : const Icon(Icons.sync),
                label: state.isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sync All Data'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety_outlined, color: AppTheme.primaryTeal, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comprehensive Sync',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                ),
                const Text('Fill all fields to sync your health record.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.primaryTeal,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
      ),
    );
  }

  Widget _buildStatusMessage(SubmissionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: state.isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: state.isSuccess ? Colors.green[100]! : Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(
            state.isSuccess ? Icons.check_circle : Icons.error,
            color: state.isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.resultMessage!,
              style: TextStyle(
                color: state.isSuccess ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
