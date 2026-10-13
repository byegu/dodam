class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiresAt;

  bool isAccessTokenExpired({DateTime? now}) {
    final expiresAt = accessTokenExpiresAt;
    if (expiresAt == null) return false;

    return !expiresAt.isAfter(now ?? DateTime.now());
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
  }) => AuthTokens(
    accessToken: REVIEW_SECRET_REMOVED
    refreshToken: REVIEW_SECRET_REMOVED
    accessTokenExpiresAt: REVIEW_SECRET_REMOVED
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokens &&
          accessToken =REVIEW_SECRET_REMOVED
          refreshToken =REVIEW_SECRET_REMOVED
          accessTokenExpiresAt == other.accessTokenExpiresAt;

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, accessTokenExpiresAt);
}
