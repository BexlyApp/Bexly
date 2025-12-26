import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';

/// DOS-Me API Service for syncing user data
class DosMeApiService {
  static const String _label = 'DosMeApi';

  // API URL - use v2 for production
  static const String baseUrl = String.fromEnvironment(
    'DOSME_API_URL',
    defaultValue: 'https://api-v2.dos.me',
  );

  // Product ID for Bexly
  static const String productId = 'bexly';

  final http.Client _client;

  DosMeApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Login with Firebase ID Token
  /// Syncs user to DOS-Me database and returns custom token
  Future<DosMeLoginResult> login(String idToken) async {
    try {
      Log.i('Logging in to DOS-Me API...', label: _label);

      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'productId': productId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>?;
        if (responseData == null) {
          return DosMeLoginResult.failure(message: 'Invalid response data');
        }

        final user = DosMeUser.fromJson(
            responseData['user'] as Map<String, dynamic>? ?? {});
        final customToken = responseData['customToken'] as String?;
        final isNew = responseData['isNew'] as bool? ?? false;

        Log.i('DOS-Me login successful: ${user.uid} (isNew: $isNew)',
            label: _label);

        return DosMeLoginResult.success(
          customToken: customToken,
          user: user,
          isNew: isNew,
        );
      }

      final message = data['message'] as String? ?? 'Login failed';
      Log.w('DOS-Me login failed: $message', label: _label);
      return DosMeLoginResult.failure(message: message);
    } catch (e) {
      Log.e('DOS-Me login error: $e', label: _label);
      return DosMeLoginResult.failure(message: e.toString());
    }
  }

  /// Verify token and get user profile
  Future<DosMeUser?> verifyToken(String idToken) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final userData =
            data['data']?['user'] as Map<String, dynamic>? ?? {};
        return DosMeUser.fromJson(userData);
      }
      return null;
    } catch (e) {
      Log.e('DOS-Me verify error: $e', label: _label);
      return null;
    }
  }

  /// Get user profile (requires auth header)
  Future<DosMeUser?> getProfile(String idToken) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final userData = data['data'] as Map<String, dynamic>? ?? {};
        return DosMeUser.fromJson(userData);
      }
      return null;
    } catch (e) {
      Log.e('DOS-Me getProfile error: $e', label: _label);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String idToken,
    String? fullname,
    String? avatar,
  }) async {
    try {
      final request = http.Request('PATCH', Uri.parse('$baseUrl/auth/me'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $idToken';
      request.body = jsonEncode({
        if (fullname != null) 'fullname': fullname,
        if (avatar != null) 'avatar': avatar,
      });

      final streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return data['success'] == true;
    } catch (e) {
      Log.e('DOS-Me updateProfile error: $e', label: _label);
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result of DOS-Me login
class DosMeLoginResult {
  final bool success;
  final String? customToken;
  final DosMeUser? user;
  final bool isNew;
  final String? message;

  DosMeLoginResult._({
    required this.success,
    this.customToken,
    this.user,
    this.isNew = false,
    this.message,
  });

  factory DosMeLoginResult.success({
    String? customToken,
    required DosMeUser user,
    bool isNew = false,
  }) =>
      DosMeLoginResult._(
        success: true,
        customToken: customToken,
        user: user,
        isNew: isNew,
      );

  factory DosMeLoginResult.failure({required String message}) =>
      DosMeLoginResult._(success: false, message: message);
}

/// DOS-Me User model
@immutable
class DosMeUser {
  final String uid;
  final String email;
  final String? fullname;
  final String? avatar;
  final String? publicAddress;
  final bool emailVerified;
  final DateTime? createdAt;

  const DosMeUser({
    required this.uid,
    required this.email,
    this.fullname,
    this.avatar,
    this.publicAddress,
    this.emailVerified = false,
    this.createdAt,
  });

  factory DosMeUser.fromJson(Map<String, dynamic> json) => DosMeUser(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullname: json['fullname'] as String?,
        avatar: json['avatar'] as String?,
        publicAddress: json['publicAddress'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'fullname': fullname,
        'avatar': avatar,
        'publicAddress': publicAddress,
        'emailVerified': emailVerified,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  String toString() => 'DosMeUser(uid: $uid, email: $email)';
}
