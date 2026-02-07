// Service for interacting with dos.me ID OAuth API
// This service manages OAuth tokens stored centrally in dos.me ID

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'dosme_oauth_models.dart';

/// Service for managing OAuth tokens via dos.me ID
///
/// This service:
/// - Fetches Gmail/Outlook access tokens from dos.me ID
/// - Lists user's OAuth connections
/// - Handles token refresh automatically (server-side)
/// - Returns proper error codes for client handling
class DosmeOAuthService {
  static const _label = 'DosmeOAuth';

  final String _baseUrl;
  final http.Client _httpClient;

  DosmeOAuthService({
    String? baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl ?? SupabaseConfig.dosMeApiUrl,
        _httpClient = httpClient ?? http.Client();

  /// Get the authorization header with dos.me ID access token
  Future<Map<String, String>> _getAuthHeaders() async {
    final session = SupabaseInitService.client.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated with dos.me ID');
    }

    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Get Gmail access token from dos.me ID
  ///
  /// This will:
  /// 1. Call dos.me ID API
  /// 2. Server refreshes token if needed
  /// 3. Return fresh access token
  ///
  /// [email] - Optional email to specify which Gmail account (for multi-account)
  Future<DosmeOAuthResult<DosmeAccessTokenResponse>> getGmailAccessToken({
    String? email,
  }) async {
    return getAccessToken(provider: 'gmail', email: email);
  }

  /// Get access token for any provider from dos.me ID
  ///
  /// API: POST /oauth/tokens/access-token
  /// Body: { provider, appId, email? }
  /// Response: { success, accessToken, expiresIn, email, scopes }
  Future<DosmeOAuthResult<DosmeAccessTokenResponse>> getAccessToken({
    required String provider,
    String? email,
  }) async {
    try {
      Log.d('Getting $provider access token from dos.me ID', label: _label);

      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/oauth/tokens/access-token';

      // Build request body
      final body = <String, dynamic>{
        'provider': provider,
        'appId': SupabaseConfig.productId,
      };
      if (email != null) {
        body['email'] = email;
      }

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse<DosmeAccessTokenResponse>(
        response,
        (json) => DosmeAccessTokenResponse.fromJson(json),
      );
    } catch (e) {
      Log.e('Failed to get $provider access token: $e', label: _label);
      return DosmeOAuthFailure(DosmeOAuthError(
        code: DosmeOAuthErrorCode.serverError,
        message: e.toString(),
      ));
    }
  }

  /// List all OAuth connections for current user
  Future<DosmeOAuthResult<List<DosmeOAuthConnection>>> getConnections() async {
    try {
      Log.d('Getting OAuth connections from dos.me ID', label: _label);

      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/oauth/tokens/connections'),
        headers: headers,
      );

      return _handleResponse<List<DosmeOAuthConnection>>(
        response,
        (json) {
          final connections = json['connections'] as List?;
          if (connections == null) return [];
          return connections
              .map((c) => DosmeOAuthConnection.fromJson(c as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      Log.e('Failed to get connections: $e', label: _label);
      return DosmeOAuthFailure(DosmeOAuthError(
        code: DosmeOAuthErrorCode.serverError,
        message: e.toString(),
      ));
    }
  }

  /// Check if Gmail is connected
  Future<bool> isGmailConnected() async {
    final result = await getConnections();
    return switch (result) {
      DosmeOAuthSuccess(data: final connections) =>
        connections.any((c) => c.provider == 'gmail' && c.isValid),
      DosmeOAuthFailure() => false,
    };
  }

  /// Get connected Gmail email address
  Future<String?> getConnectedGmailEmail() async {
    final result = await getConnections();
    return switch (result) {
      DosmeOAuthSuccess(data: final connections) => connections
          .where((c) => c.provider == 'gmail' && c.isValid)
          .map((c) => c.email)
          .firstOrNull,
      DosmeOAuthFailure() => null,
    };
  }

  /// Exchange authorization code from native Google Sign In
  ///
  /// API: POST /oauth/tokens/exchange
  /// Body: { provider, code, appId, redirectUri?, codeVerifier? }
  /// Response: { success, connectionId, email, scopes }
  ///
  /// This allows native mobile apps to:
  /// 1. Use native Google Sign In to get auth code
  /// 2. Send code to dos.me ID for exchange
  /// 3. dos.me ID stores refresh token securely
  Future<DosmeOAuthResult<DosmeExchangeResponse>> exchangeAuthCode({
    required String provider,
    required String code,
    String? redirectUri,
    String? codeVerifier,
  }) async {
    try {
      Log.d('Exchanging $provider auth code with dos.me ID', label: _label);

      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/oauth/tokens/exchange';

      // Build request body
      final body = <String, dynamic>{
        'provider': provider,
        'code': code,
        'appId': SupabaseConfig.productId,
      };
      if (redirectUri != null) {
        body['redirectUri'] = redirectUri;
      }
      if (codeVerifier != null) {
        body['codeVerifier'] = codeVerifier;
      }

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse<DosmeExchangeResponse>(
        response,
        (json) => DosmeExchangeResponse.fromJson(json),
      );
    } catch (e) {
      Log.e('Failed to exchange $provider auth code: $e', label: _label);
      return DosmeOAuthFailure(DosmeOAuthError(
        code: DosmeOAuthErrorCode.serverError,
        message: e.toString(),
      ));
    }
  }

  /// Exchange Gmail auth code from native Google Sign In
  Future<DosmeOAuthResult<DosmeExchangeResponse>> exchangeGmailAuthCode({
    required String code,
    String? redirectUri,
    String? codeVerifier,
  }) async {
    return exchangeAuthCode(
      provider: 'gmail',
      code: code,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
    );
  }

  /// Get the URL to connect Gmail via dos.me ID web
  ///
  /// API: GET /oauth/gmail/connect?app_id=bexly&redirect_uri=...
  /// Opens dos.me ID OAuth flow in browser, user authorizes,
  /// then returns to app with connection established
  String getConnectGmailUrl({String? redirectUri}) {
    final uri = Uri.parse('$_baseUrl/oauth/gmail/connect');
    final params = <String, String>{
      'app_id': SupabaseConfig.productId,
    };
    if (redirectUri != null) {
      params['redirect_uri'] = redirectUri;
    }
    return uri.replace(queryParameters: params).toString();
  }

  /// Handle API response and parse to result type
  DosmeOAuthResult<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      Log.e('Unexpected API response type: ${decoded.runtimeType}, body: ${response.body}', label: _label);
      return DosmeOAuthFailure(DosmeOAuthError(
        code: _statusCodeToErrorCode(response.statusCode),
        message: 'Unexpected response: ${response.body}',
      ));
    }
    final json = decoded;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Log.d('API success: ${response.statusCode}', label: _label);
      return DosmeOAuthSuccess(parser(json));
    }

    // Parse error response — handle both Map and String error formats
    final rawError = json['error'];
    if (rawError is Map<String, dynamic>) {
      final oauthError = DosmeOAuthError.fromJson(rawError);
      Log.w('API error: ${oauthError.code} - ${oauthError.message}', label: _label);
      return DosmeOAuthFailure(oauthError);
    }

    // Generic error (error is a string or missing)
    final errorCode = _statusCodeToErrorCode(response.statusCode);
    final errorMessage = rawError?.toString() ?? json['message']?.toString() ?? 'Unknown error';
    return DosmeOAuthFailure(DosmeOAuthError(
      code: errorCode,
      message: errorMessage,
    ));
  }

  String _statusCodeToErrorCode(int statusCode) {
    return switch (statusCode) {
      401 => DosmeOAuthErrorCode.unauthorized,
      404 => DosmeOAuthErrorCode.connectionNotFound,
      429 => DosmeOAuthErrorCode.rateLimited,
      _ => DosmeOAuthErrorCode.serverError,
    };
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
