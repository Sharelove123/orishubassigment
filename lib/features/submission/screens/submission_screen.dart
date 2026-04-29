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
  final _stepsController = TextEditingController(text: '11178');
  final _latController = TextEditingController(text: '18.2915625');
  final _longController = TextEditingController(text: '79.4695052');
  final _deviceIdController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _stepsController.dispose();
    _latController.dispose();
    _longController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    return {
      "sleep": [],
      "steps": [
        {
          "type": "STEPS",
          "unit": "COUNT",
          "value": _stepsController.text,
          "end_time": DateTime.now().toIso8601String(),
          "platform": "android",
          "start_time": DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
          "source_name": "health_connect"
        }
      ],
      "weight": [],
      "calories": [],
      "location": [
        {
          "speed": 0,
          "accuracy": 128.8990020751953,
          "altitude": 181.40000915527344,
          "latitude": double.tryParse(_latController.text) ?? 0.0,
          "platform": "android",
          "longitude": double.tryParse(_longController.text) ?? 0.0,
          "timestamp": DateTime.now().toIso8601String()
        }
      ],
      "heart_rate": []
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polso Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.primaryTeal, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Your Data',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkNavy,
                              ),
                        ),
                        const Text('Enter health metrics below'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInputSection('Device Info', [
              _buildTextField(_deviceIdController, 'Device ID', Icons.devices),
            ]),
            const SizedBox(height: 24),
            _buildInputSection('Activity', [
              _buildTextField(_stepsController, 'Steps Count', Icons.directions_walk, keyboardType: TextInputType.number),
            ]),
            const SizedBox(height: 24),
            _buildInputSection('Location', [
              Row(
                children: [
                  Expanded(child: _buildTextField(_latController, 'Latitude', Icons.location_on, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_longController, 'Longitude', Icons.location_on, keyboardType: TextInputType.number)),
                ],
              ),
            ]),
            const SizedBox(height: 32),
            if (state.resultMessage != null)
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: state.isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: state.isSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.resultMessage!,
                          style: TextStyle(
                            color: state.isSuccess ? Colors.green[800] : Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                icon: state.isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.cloud_upload_outlined),
                label: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Health Data'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
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
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
      ),
    );
  }
}
