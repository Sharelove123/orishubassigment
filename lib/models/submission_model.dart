class SubmissionResponse {
  final String message;
  final int? id;
  final Map<String, dynamic>? submission;

  SubmissionResponse({required this.message, this.id, this.submission});

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      message: json['message'] ?? '',
      id: json['id'],
      submission: json['submission'],
    );
  }
}
