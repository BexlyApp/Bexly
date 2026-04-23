import 'dart:io';
import 'dart:convert';

void addStrings(String lang, Map<String, dynamic> newStrings) {
  final path = 'lib/l10n/app_$lang.arb';
  final content = File(path).readAsStringSync();
  final data = jsonDecode(content) as Map<String, dynamic>;
  data.addAll(newStrings);
  File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  print('Updated $path');
}

void main() {
  addStrings('en', {
    'dueToday': 'Today',
    'overdue': 'Overdue',
    'dueInDays': 'Due in {days} days',
    '@dueInDays': {'placeholders': {'days': {'type': 'int'}}},
    'frequencyDaily': 'Daily',
    'frequencyWeekly': 'Weekly',
    'frequencyMonthly': 'Monthly',
    'frequencyQuarterly': 'Quarterly',
    'frequencyYearly': 'Yearly',
    'frequencyCustom': 'Custom',
    'aiDetectedRecurring': 'AI detected {count} patterns',
    '@aiDetectedRecurring': {'placeholders': {'count': {'type': 'int'}}},
  });
  addStrings('vi', {
    'dueToday': 'Hôm nay',
    'overdue': 'Quá hạn',
    'dueInDays': 'Còn {days} ngày',
    '@dueInDays': {'placeholders': {'days': {'type': 'int'}}},
    'frequencyDaily': 'Hàng ngày',
    'frequencyWeekly': 'Hàng tuần',
    'frequencyMonthly': 'Hàng tháng',
    'frequencyQuarterly': 'Hàng quý',
    'frequencyYearly': 'Hàng năm',
    'frequencyCustom': 'Tùy chỉnh',
    'aiDetectedRecurring': 'AI phát hiện {count} khoản định kỳ',
    '@aiDetectedRecurring': {'placeholders': {'count': {'type': 'int'}}},
  });
}
