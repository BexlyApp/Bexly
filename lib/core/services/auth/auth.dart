/// Auth services barrel file.
///
/// This file exports Supabase authentication services.
/// Firebase Auth has been removed - app is now Supabase-only.

// Supabase Auth (primary auth system)
export 'supabase_auth_service.dart';

// DOS-Me API service removed - use direct Supabase access (first-party app)
// If need DOS-Me API in future, implement OAuth 2.1 PKCE flow
