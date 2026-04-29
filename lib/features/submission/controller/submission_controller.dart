import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class SubmissionState {
  final bool isSubmitting;
  final String? resultMessage;
  final bool isSuccess;

  SubmissionState({this.isSubmitting = false, this.resultMessage, this.isSuccess = false});

  SubmissionState copyWith({bool? isSubmitting, String? resultMessage, bool? isSuccess}) {
    return SubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      resultMessage: resultMessage ?? this.resultMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SubmissionController extends Notifier<SubmissionState> {
  @override
  SubmissionState build() => SubmissionState();

  Future<void> submitData(Map<String, dynamic> payload, {required String deviceId}) async {
    state = state.copyWith(isSubmitting: true, resultMessage: null, isSuccess: false);
    try {
      final repo = ref.read(submissionRepositoryProvider);
      final result = await repo.submitData(
        type: 'polso health',
        deviceId: deviceId,
        payload: payload,
      );
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        resultMessage: result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        resultMessage: e.toString(),
      );
    }
  }
}

final submissionControllerProvider = NotifierProvider<SubmissionController, SubmissionState>(() {
  return SubmissionController();
});
