// Models for dos.me ID OAuth API responses
// Manual implementation to avoid Freezed v3.2.0 code generation bug

/// OAuth connection from dos.me ID
class DosmeOAuthConnection {
  final String id;
  final String provider;
  final String? email;
  final List<String> scopes;
  final DateTime connectedAt;
  final DateTime? lastUsedAt;
  final bool isValid;

  const DosmeOAuthConnection({
    required this.id,
    required this.provider,
    this.email,
    required this.scopes,
    required this.connectedAt,
    this.lastUsedAt,
    required this.isValid,
  });

  factory DosmeOAuthConnection.fromJson(Map<String, dynamic> json) {
    return DosmeOAuthConnection(
      id: json['id'] as String,
      provider: json['provider'] as String,
      email: json['email'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)?.cast<String>() ?? [],
      connectedAt: DateTime.parse(json['connected_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      isValid: json['is_valid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'email': email,
      'scopes': scopes,
      'connected_at': connectedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'is_valid': isValid,
    };
  }

  @override
  String toString() =>
      'DosmeOAuthConnection(id: $id, provider: $provider, email: $email, isValid: $isValid)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DosmeOAuthConnection &&
          other.id == id &&
          other.provider == provider &&
          other.email == email;

  @override
  int get hashCode => Object.hash(id, provider, email);
}

/// Access token response from dos.me ID
class DosmeAccessTokenResponse {
  final String accessToken;
  final int expiresIn;
  final String? email;
  final List<String>? scopes;

  const DosmeAccessTokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.email,
    this.scopes,
  });

  factory DosmeAccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return DosmeAccessTokenResponse(
      // Backend uses camelCase: accessToken, expiresIn
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
      email: json['email'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiresIn': expiresIn,
      'email': email,
      'scopes': scopes,
    };
  }

  @override
  String toString() =>
      'DosmeAccessTokenResponse(email: $email, expiresIn: $expiresIn)';
}

/// Response from exchanging auth code with dos.me ID
class DosmeExchangeResponse {
  final String connectionId;
  final String email;
  final List<String>? scopes;

  const DosmeExchangeResponse({
    required this.connectionId,
    required this.email,
    this.scopes,
  });

  factory DosmeExchangeResponse.fromJson(Map<String, dynamic> json) {
    return DosmeExchangeResponse(
      connectionId: json['connectionId'] as String,
      email: json['email'] as String,
      scopes: (json['scopes'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'email': email,
      'scopes': scopes,
    };
  }

  @override
  String toString() =>
      'DosmeExchangeResponse(connectionId: $connectionId, email: $email)';
}

/// Error response from dos.me ID OAuth API
class DosmeOAuthError {
  final String code;
  final String message;
  final String? action;
  final String? provider;
  final String? email;
  final int? retryAfter;

  const DosmeOAuthError({
    required this.code,
    required this.message,
    this.action,
    this.provider,
    this.email,
    this.retryAfter,
  });

  factory DosmeOAuthError.fromJson(Map<String, dynamic> json) {
    return DosmeOAuthError(
      code: json['code'] as String,
      message: json['message'] as String,
      action: json['action'] as String?,
      provider: json['provider'] as String?,
      email: json['email'] as String?,
      retryAfter: json['retry_after'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'action': action,
      'provider': provider,
      'email': email,
      'retry_after': retryAfter,
    };
  }

  @override
  String toString() => 'DosmeOAuthError(code: $code, message: $message)';

  /// Check if this error requires re-authorization
  bool get requiresReAuth =>
      code == DosmeOAuthErrorCode.tokenRevoked ||
      code == DosmeOAuthErrorCode.scopeInsufficient;

  /// Check if this error is temporary and can be retried
  bool get isRetryable => code == DosmeOAuthErrorCode.rateLimited;
}

/// Error codes from dos.me ID OAuth API
class DosmeOAuthErrorCode {
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String tokenRevoked = 'TOKEN_REVOKED';
  static const String scopeInsufficient = 'SCOPE_INSUFFICIENT';
  static const String connectionNotFound = 'CONNECTION_NOT_FOUND';
  static const String rateLimited = 'RATE_LIMITED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String serverError = 'SERVER_ERROR';
}

/// Result of dos.me OAuth operations
sealed class DosmeOAuthResult<T> {
  const DosmeOAuthResult();
}

class DosmeOAuthSuccess<T> extends DosmeOAuthResult<T> {
  final T data;
  const DosmeOAuthSuccess(this.data);

  @override
  String toString() => 'DosmeOAuthSuccess(data: $data)';
}

class DosmeOAuthFailure<T> extends DosmeOAuthResult<T> {
  final DosmeOAuthError error;
  const DosmeOAuthFailure(this.error);

  @override
  String toString() => 'DosmeOAuthFailure(error: $error)';
}
