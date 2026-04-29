class LoginResponse {
  final String token;
  final String? message;

  LoginResponse({required this.token, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? json['access_token'] ?? '',
      message: json['message'],
    );
  }
}
