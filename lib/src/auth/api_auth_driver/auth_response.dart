class AuthResponse {
  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  String accessToken;
  String? refreshToken;
  int? expiresIn;
  Map<String, dynamic>? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresIn: json['expiresIn'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'user': user,
    };
  }
}
