// Riverpod providers for DosmeOAuthService
// Using manual providers (riverpod_generator not enabled)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dosme_oauth_service.dart';
import 'dosme_oauth_models.dart';

/// Provider for DosmeOAuthService singleton
final dosmeOAuthServiceProvider = Provider<DosmeOAuthService>((ref) {
  final service = DosmeOAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for checking Gmail connection status via dos.me ID
final isGmailConnectedViaDosmeProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(dosmeOAuthServiceProvider);
  return service.isGmailConnected();
});

/// Provider for getting connected Gmail email via dos.me ID
final connectedGmailEmailViaDosmeProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(dosmeOAuthServiceProvider);
  return service.getConnectedGmailEmail();
});

/// Provider for listing all OAuth connections from dos.me ID
final dosmeOAuthConnectionsProvider = FutureProvider<List<DosmeOAuthConnection>>((ref) async {
  final service = ref.watch(dosmeOAuthServiceProvider);
  final result = await service.getConnections();
  return switch (result) {
    DosmeOAuthSuccess(data: final connections) => connections,
    DosmeOAuthFailure() => [],
  };
});

/// Provider for getting Gmail access token from dos.me ID
/// Use this provider in email sync to get fresh access tokens
final gmailAccessTokenViaDosmeProvider = FutureProvider.family<DosmeOAuthResult<DosmeAccessTokenResponse>, String?>((ref, email) async {
  final service = ref.watch(dosmeOAuthServiceProvider);
  return service.getGmailAccessToken(email: email);
});
