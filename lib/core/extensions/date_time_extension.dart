import 'package:intl/intl.dart';

/// Helper to check if current locale is Vietnamese
bool get _isVietnameseLocale {
  final locale = Intl.getCurrentLocale();
  return locale.startsWith('vi');
}

/// Localized "Today" string based on current locale
String get _localizedToday {
  final locale = Intl.getCurrentLocale();
  return switch (locale) {
    'vi' => 'Hôm nay',
    'zh' => '今天',
    'fr' => "Aujourd'hui",
    'th' => 'วันนี้',
    'id' => 'Hari ini',
    'es' => 'Hoy',
    'pt' => 'Hoje',
    _ => 'Today',
  };
}

/// Localized "Yesterday" string based on current locale
String get _localizedYesterday {
  final locale = Intl.getCurrentLocale();
  return switch (locale) {
    'vi' => 'Hôm qua',
    'zh' => '昨天',
    'fr' => 'Hier',
    'th' => 'เมื่อวาน',
    'id' => 'Kemarin',
    'es' => 'Ayer',
    'pt' => 'Ontem',
    _ => 'Yesterday',
  };
}

/// Localized "This Month" string based on current locale
String get _localizedThisMonth {
  final locale = Intl.getCurrentLocale();
  return switch (locale) {
    'vi' => 'Tháng này',
    'zh' => '本月',
    'fr' => 'Ce mois-ci',
    'th' => 'เดือนนี้',
    'id' => 'Bulan ini',
    'es' => 'Este mes',
    'pt' => 'Este mês',
    _ => 'This Month',
  };
}

/// Localized "Last Month" string based on current locale
String get _localizedLastMonth {
  final locale = Intl.getCurrentLocale();
  return switch (locale) {
    'vi' => 'Tháng trước',
    'zh' => '上个月',
    'fr' => 'Le mois dernier',
    'th' => 'เดือนที่แล้ว',
    'id' => 'Bulan lalu',
    'es' => 'El mes pasado',
    'pt' => 'Mês passado',
    _ => 'Last Month',
  };
}

extension DateTimeExtension on DateTime {
  /// Format: March
  String toMonthName() {
    return DateFormat("MMMM").format(this);
  }

  /// Format: 13 March 2025
  String toDayMonthYear() {
    return DateFormat("d MMMM yyyy").format(this);
  }

  /// Format: 12 Nov 2024
  String toDayShortMonth() {
    return DateFormat("d MMM").format(this);
  }

  /// Format: 12 Nov 2024
  String toDayShortMonthYear() {
    return DateFormat("d MMM yyyy").format(this);
  }

  /// Format: March 13, 2025
  String toMonthDayYear() {
    return DateFormat("MMMM d, yyyy").format(this);
  }

  /// Format: 13/03/2025
  String toDayMonthYearNumeric() {
    return DateFormat("dd/MM/yyyy").format(this);
  }

  /// Format: 03/2025
  String toMonthYearNumeric() {
    return DateFormat("MM/yyyy").format(this);
  }

  /// Format: Oct 2024
  String toMonthYear() {
    return DateFormat("MMM yyyy").format(this);
  }

  DateTime get toMidnightStart {
    return DateTime(year, month, day);
  }

  DateTime get toMidnightEnd {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Returns date in relative format with optional time.
  /// Examples:
  /// - "Today, 10.22" (with showTime: true, use24Hours: true)
  /// - "Today, 10.22 AM" (with showTime: true, use24Hours: false)
  /// - "Yesterday, 15.23" (with showTime: true, use24Hours: true)
  /// - "Yesterday, 03.23 PM" (with showTime: true, use24Hours: false)
  /// - "13 June 2025, 10.22" (with showTime: true, use24Hours: true)
  /// - "13 June 2025, 10.22 AM" (with showTime: true, use24Hours: false)
  /// - "Today" (with showTime: false)
  String toRelativeDayFormatted({
    bool showTime = false,
    bool use24Hours = true,
  }) {
    final now = DateTime.now();
    // Normalize dates to midnight for accurate day difference
    final thisDateAtMidnight = DateTime(year, month, day);
    final nowDateAtMidnight = DateTime(now.year, now.month, now.day);

    final differenceInDays = nowDateAtMidnight
        .difference(thisDateAtMidnight)
        .inDays;

    String baseText;
    if (differenceInDays == 0) {
      baseText = _localizedToday;
    } else if (differenceInDays == 1) {
      baseText = _localizedYesterday;
    } else {
      baseText = toDayMonthYear();
    }

    if (showTime) {
      // Vietnamese uses 24h format, English uses 12h format
      final shouldUse24h = use24Hours || _isVietnameseLocale;
      final time = shouldUse24h
          ? DateFormat("HH:mm").format(this)
          : DateFormat("h:mm a").format(this);
      return "$baseText, $time";
    }
    return baseText;
  }

  /// Returns localized "This Month", "Last Month", or "Oct 2024" for tab labels.
  /// Compares `this` month to the `currentDate` month.
  String toMonthTabLabel(DateTime currentDate) {
    final thisMonthStart = DateTime(year, month, 1);
    final currentMonthStart = DateTime(currentDate.year, currentDate.month, 1);
    final lastMonthStart = DateTime(currentDate.year, currentDate.month - 1, 1);

    if (thisMonthStart.year == currentMonthStart.year &&
        thisMonthStart.month == currentMonthStart.month) {
      return _localizedThisMonth;
    }
    if (thisMonthStart.year == lastMonthStart.year &&
        thisMonthStart.month == lastMonthStart.month) {
      return _localizedLastMonth;
    }
    return DateFormat("MMM yyyy").format(this); // e.g., "Oct 2024"
  }

  /// Format: 13 March 2025 05.44 am / 13 March 2025 05.44 pm
  String toDayMonthYearTime12Hour() {
    return DateFormat("d MMMM yyyy hh.mm a").format(this);
  }

  /// Format: 13 March 2025 17.44
  String toDayMonthYearTime24Hour() {
    return DateFormat("d MMMM yyyy HH.mm").format(this);
  }

  /// Returns only time formatted.
  /// Vietnamese: 24h format (18:45), English: 12h format (6:45 PM)
  String toTimeFormatted({bool? use24Hours}) {
    // Auto-detect based on locale if not specified
    final shouldUse24h = use24Hours ?? _isVietnameseLocale;
    if (shouldUse24h) {
      return DateFormat("HH:mm").format(this);
    }
    return DateFormat("h:mm a").format(this);
  }
}
