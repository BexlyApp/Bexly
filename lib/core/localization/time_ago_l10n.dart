import 'package:bexly/core/localization/generated/app_localizations.dart';

/// Extension for time-ago display strings that require pluralization logic
/// beyond what ARB ICU format provides cleanly.
extension TimeAgoL10n on AppLocalizations {
  String minutesAgo(int count) {
    if (localeName == 'vi') return '$count phút trước';
    return count == 1 ? '1 minute ago' : '$count minutes ago';
  }

  String hoursAgo(int count) {
    if (localeName == 'vi') return '$count giờ trước';
    return count == 1 ? '1 hour ago' : '$count hours ago';
  }
}
