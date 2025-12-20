import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:bexly/core/utils/logger.dart';

/// Gmail message model
class GmailMessage {
  final String id;
  final String threadId;
  final String subject;
  final String from;
  final String body;
  final DateTime date;
  final String snippet;

  const GmailMessage({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.from,
    required this.body,
    required this.date,
    required this.snippet,
  });

  @override
  String toString() => 'GmailMessage(id: $id, from: $from, subject: $subject)';
}

/// Service for fetching emails using Gmail API
class GmailApiService {
  static const _label = 'GmailApi';
  static const _baseUrl = 'https://gmail.googleapis.com/gmail/v1';

  // Vietnamese banks and e-wallets
  static const List<String> vietnamBankDomains = [
    'vietcombank.com.vn',
    'alert.vietcombank.com.vn',
    'bidv.com.vn',
    'notification.bidv.com.vn',
    'techcombank.com.vn',
    'vpbank.com.vn',
    'mbbank.com.vn',
    'acb.com.vn',
    'tpb.vn',
    'tpbank.vn',
    'sacombank.com.vn',
    'hdbank.com.vn',
    'vib.com.vn',
    'msb.com.vn',
    'seabank.com.vn',
    'lpbank.com.vn',
    'namabank.com.vn',
    'ocb.com.vn',
    'shb.com.vn',
    'eximbank.com.vn',
    'abbank.vn',
    'pvcombank.com.vn',
    'baovietbank.com.vn',
    'kienlongbank.com.vn',
    'vietbank.com.vn',
    'ncb-bank.vn',
    'gpbank.com.vn',
    'oceanbank.vn',
    'saigonbank.com.vn',
    'bvbank.net.vn',
  ];

  // E-wallets
  static const List<String> ewalletDomains = [
    'momo.vn',
    'zalopay.vn',
    'vnpay.vn',
    'shopeepay.vn',
    'viettelpay.vn',
  ];

  // International banks
  static const List<String> internationalBankDomains = [
    'chase.com',
    'alerts.chase.com',
    'citi.com',
    'notifications.citi.com',
    'email.capitalone.com',
    'alerts.bankofamerica.com',
    'wellsfargo.com',
    'hsbc.com',
    'americanexpress.com',
    'discover.com',
    'paypal.com',
    'wise.com',
  ];

  /// Get all supported bank domains
  static List<String> get allBankDomains => [
        ...vietnamBankDomains,
        ...ewalletDomains,
        ...internationalBankDomains,
      ];

  /// Build Gmail search query for banking emails
  static String buildBankEmailQuery({
    DateTime? since,
    List<String>? filterDomains,
  }) {
    final domains = filterDomains ?? allBankDomains;
    final fromQuery = domains.map((d) => 'from:$d').join(' OR ');

    String query = '($fromQuery)';

    if (since != null) {
      // Gmail uses epoch seconds
      final epochSeconds = since.millisecondsSinceEpoch ~/ 1000;
      query += ' after:$epochSeconds';
    }

    return query;
  }

  /// Fetch banking emails from Gmail
  /// Throws exception if authentication fails
  Future<List<GmailMessage>> fetchBankingEmails({
    DateTime? since,
    List<String>? filterDomains,
    int maxResults = 50,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      Log.w('No access token available', label: _label);
      throw Exception('Gmail not authorized. Please reconnect your Gmail account.');
    }

    try {

      // Build query
      final query = buildBankEmailQuery(
        since: since,
        filterDomains: filterDomains,
      );

      Log.d('Fetching emails with query: $query', label: _label);

      // List messages matching query
      final listUrl = Uri.parse(
        '$_baseUrl/users/me/messages?q=${Uri.encodeComponent(query)}&maxResults=$maxResults',
      );

      final listResponse = await http.get(
        listUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (listResponse.statusCode != 200) {
        Log.e('Failed to list messages: ${listResponse.statusCode}', label: _label);
        Log.e('Response: ${listResponse.body}', label: _label);
        return [];
      }

      final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
      final messageIds = (listData['messages'] as List<dynamic>?)
              ?.map((m) => m['id'] as String)
              .toList() ??
          [];

      Log.d('Found ${messageIds.length} banking emails', label: _label);

      if (messageIds.isEmpty) {
        return [];
      }

      // Fetch each message in detail
      final messages = <GmailMessage>[];
      for (final messageId in messageIds) {
        final message = await _fetchMessageDetails(accessToken, messageId);
        if (message != null) {
          messages.add(message);
        }
      }

      return messages;
    } catch (e, stack) {
      Log.e('Error fetching emails: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return [];
    }
  }

  /// Fetch a single message by ID
  Future<GmailMessage?> _fetchMessageDetails(
    String accessToken,
    String messageId,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/users/me/messages/$messageId?format=full',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        Log.w('Failed to fetch message $messageId: ${response.statusCode}', label: _label);
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseMessage(data);
    } catch (e) {
      Log.w('Error fetching message $messageId: $e', label: _label);
      return null;
    }
  }

  /// Parse Gmail API response into GmailMessage
  GmailMessage? _parseMessage(Map<String, dynamic> data) {
    try {
      final id = data['id'] as String;
      final threadId = data['threadId'] as String;
      final snippet = data['snippet'] as String? ?? '';

      // Parse headers
      final payload = data['payload'] as Map<String, dynamic>?;
      final headers = (payload?['headers'] as List<dynamic>?) ?? [];

      String subject = '';
      String from = '';
      DateTime? date;

      for (final header in headers) {
        final name = (header['name'] as String).toLowerCase();
        final value = header['value'] as String? ?? '';

        switch (name) {
          case 'subject':
            subject = value;
            break;
          case 'from':
            from = value;
            break;
          case 'date':
            date = _parseEmailDate(value);
            break;
        }
      }

      // Parse body
      final body = _extractBody(payload);

      return GmailMessage(
        id: id,
        threadId: threadId,
        subject: subject,
        from: from,
        body: body,
        date: date ?? DateTime.now(),
        snippet: snippet,
      );
    } catch (e) {
      Log.w('Error parsing message: $e', label: _label);
      return null;
    }
  }

  /// Extract body from message payload
  String _extractBody(Map<String, dynamic>? payload) {
    if (payload == null) return '';

    // Try to get body directly
    final body = payload['body'] as Map<String, dynamic>?;
    if (body != null) {
      final data = body['data'] as String?;
      if (data != null && data.isNotEmpty) {
        return _decodeBase64Url(data);
      }
    }

    // Try parts (multipart message)
    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      for (final part in parts) {
        final mimeType = part['mimeType'] as String?;
        if (mimeType == 'text/plain' || mimeType == 'text/html') {
          final partBody = part['body'] as Map<String, dynamic>?;
          final data = partBody?['data'] as String?;
          if (data != null && data.isNotEmpty) {
            return _decodeBase64Url(data);
          }
        }

        // Nested parts
        final nestedParts = part['parts'] as List<dynamic>?;
        if (nestedParts != null) {
          for (final nested in nestedParts) {
            final nestedMimeType = nested['mimeType'] as String?;
            if (nestedMimeType == 'text/plain') {
              final nestedBody = nested['body'] as Map<String, dynamic>?;
              final nestedData = nestedBody?['data'] as String?;
              if (nestedData != null && nestedData.isNotEmpty) {
                return _decodeBase64Url(nestedData);
              }
            }
          }
        }
      }
    }

    return '';
  }

  /// Decode base64url encoded string
  String _decodeBase64Url(String encoded) {
    try {
      // Replace URL-safe chars with standard base64
      String normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');

      // Add padding if needed
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final bytes = base64Decode(normalized);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      return '';
    }
  }

  /// Parse email date string
  DateTime? _parseEmailDate(String dateStr) {
    try {
      // Try RFC 2822 format first
      // Example: "Mon, 25 Dec 2024 10:30:00 +0700"
      final rfc2822Pattern = RegExp(
        r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
      );
      final match = rfc2822Pattern.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = _monthToInt(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        return DateTime(year, month, day, hour, minute, second);
      }

      // Fallback to DateTime.parse
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Convert month abbreviation to int
  int _monthToInt(String month) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  /// Gmail readonly scope for fetching emails
  static const List<String> _gmailScopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  // Cache the access token to avoid repeated auth prompts
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Get access token from Google Sign In
  ///
  /// In google_sign_in 7.x:
  /// - Authentication and authorization are separate steps
  /// - `authorizationForScopes()` returns null if UI needed (silent only)
  /// - `authorizeScopes()` shows UI if needed
  Future<String?> _getAccessToken({bool forceRefresh = false}) async {
    try {
      // Return cached token if still valid (not expired and not forcing refresh)
      if (!forceRefresh &&
          _cachedAccessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        Log.d('Using cached access token', label: _label);
        return _cachedAccessToken;
      }

      final signIn = GoogleSignIn.instance;

      // Try lightweight auth first (similar to old signInSilently)
      final user = await signIn.attemptLightweightAuthentication();
      if (user == null) {
        Log.w('No lightweight auth, user needs to sign in', label: _label);
        _cachedAccessToken = null;
        _tokenExpiry = null;
        return null;
      }

      // In google_sign_in 7.x:
      // - authorizationForScopes() returns null if UI would be needed (silent only)
      // - authorizeScopes() shows UI if needed
      final authorization = await user.authorizationClient.authorizationForScopes(
        _gmailScopes,
      );

      if (authorization != null) {
        _cachedAccessToken = authorization.accessToken;
        // Token typically valid for 1 hour, cache for 50 minutes to be safe
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
        return _cachedAccessToken;
      }

      // authorizationForScopes returned null, meaning UI is needed
      // This happens when scopes haven't been granted yet
      Log.w('No silent authorization for Gmail scopes, may need interactive auth', label: _label);

      // Don't automatically show UI here - let the caller decide
      // The user should use connectGmail() first to grant permissions
      _cachedAccessToken = null;
      _tokenExpiry = null;
      return null;
    } catch (e) {
      Log.e('Error getting access token: $e', label: _label);
      _cachedAccessToken = null;
      _tokenExpiry = null;
      return null;
    }
  }

  /// Clear cached token (call when disconnecting)
  void clearCachedToken() {
    _cachedAccessToken = null;
    _tokenExpiry = null;
  }

  /// Check if Gmail is connected (has valid token)
  Future<bool> isConnected() async {
    final token = await _getAccessToken();
    return token != null;
  }
}
