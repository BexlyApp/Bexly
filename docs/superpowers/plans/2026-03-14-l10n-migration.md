# Flutter Official L10n Migration Plan

> **For agentic workers:** REQUIRED: Use `superpowers:executing-plans` to implement this plan.

**Goal:** Migrate from custom hardcoded `AppLocalizations` map (6553 lines) to Flutter official `flutter gen-l10n` with `.arb` files.

**Architecture:** Extract all strings from the current `_localizedValues` map into per-language `.arb` files under `lib/l10n/`, use `flutter gen-l10n` to auto-generate typed `AppLocalizations`, keep the same `context.l10n.xxx` API so no call-sites change.

**Tech Stack:** `flutter_localizations` (sdk), `intl ^0.20.2` (already installed), `flutter gen-l10n` CLI, ICU message format for plurals.

---

## Chunk 1: Setup & Extraction Script

### Task 1: Configure pubspec.yaml and l10n.yaml

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`

- [ ] **Step 1: Add flutter_localizations and enable generate**

In `pubspec.yaml`, under `dependencies:`, add:
```yaml
  flutter_localizations:
    sdk: flutter
```
Under `flutter:`, add:
```yaml
  generate: true
```

- [ ] **Step 2: Create l10n.yaml**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/core/localization/generated
nullable-getter: false
```

- [ ] **Step 3: Create lib/l10n directory**
```bash
mkdir -p lib/l10n
```

- [ ] **Step 4: Commit setup**
```bash
git add pubspec.yaml l10n.yaml
git commit -m "chore(l10n): add flutter_localizations and gen config"
```

---

### Task 2: Write extraction script

**Files:**
- Create: `scripts/extract_arb.dart`

This script parses `lib/core/localization/app_localizations.dart` and outputs one `.arb` file per language under `lib/l10n/`.

- [ ] **Step 1: Create scripts directory and extraction script**

```dart
// scripts/extract_arb.dart
// Run with: dart run scripts/extract_arb.dart
import 'dart:io';
import 'dart:convert';

void main() {
  final src = File('lib/core/localization/app_localizations.dart').readAsStringSync();

  // Languages to extract
  final languages = ['en', 'vi', 'zh', 'fr', 'th', 'id', 'es', 'pt', 'ja', 'ko', 'de', 'hi', 'ru', 'ar'];

  for (final lang in languages) {
    final map = _extractLanguageMap(src, lang);
    if (map.isEmpty) {
      print('⚠️  No entries found for $lang, skipping.');
      continue;
    }

    // Build ARB JSON (@@locale must be first)
    final arb = <String, dynamic>{'@@locale': lang};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      // Convert {count}/{name}/{amount} placeholders to ICU format
      arb[key] = _convertToIcu(value);

      // Add @key metadata if there are placeholders
      final placeholders = _extractPlaceholders(value);
      if (placeholders.isNotEmpty) {
        arb['@$key'] = {
          'placeholders': {
            for (final p in placeholders)
              p: {'type': p == 'count' ? 'int' : 'String'},
          },
        };
      }
    }

    final output = const JsonEncoder.withIndent('  ').convert(arb);
    File('lib/l10n/app_$lang.arb').writeAsStringSync(output);
    print('✅  lib/l10n/app_$lang.arb — ${map.length} strings');
  }
}

/// Extract {key: value} map for the given language from the Dart source.
Map<String, String> _extractLanguageMap(String src, String lang) {
  // Find "'lang': {" block
  final startPattern = "'$lang': {";
  final startIdx = src.indexOf(startPattern);
  if (startIdx == -1) return {};

  // Find the matching closing brace
  int braceCount = 0;
  int blockStart = src.indexOf('{', startIdx + startPattern.length - 1);
  int i = blockStart;
  int blockEnd = -1;

  while (i < src.length) {
    if (src[i] == '{') braceCount++;
    if (src[i] == '}'.trimRight()[0]) {
      braceCount--;
      if (braceCount == 0) {
        blockEnd = i;
        break;
      }
    }
    i++;
  }

  if (blockEnd == -1) return {};
  final block = src.substring(blockStart + 1, blockEnd);

  // Parse "'key': 'value'" pairs
  final result = <String, String>{};
  final regex = RegExp(r"'(\w+)':\s*'((?:[^'\\]|\\.|'')*)'");
  for (final match in regex.allMatches(block)) {
    final key = match.group(1)!;
    final value = match.group(2)!
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\n', '\n');
    result[key] = value;
  }
  return result;
}

/// Convert {name} style placeholders to ARB-compatible {name} (they're already compatible).
String _convertToIcu(String value) => value;

/// Extract placeholder names like {count}, {name} from a string.
List<String> _extractPlaceholders(String value) {
  final regex = RegExp(r'\{(\w+)\}');
  return regex.allMatches(value).map((m) => m.group(1)!).toSet().toList();
}
```

- [ ] **Step 2: Run the extraction script**
```bash
dart run scripts/extract_arb.dart
```
Expected output: 14 lines like `✅  lib/l10n/app_en.arb — XXX strings`

- [ ] **Step 3: Spot-check app_en.arb and app_vi.arb**
- Open `lib/l10n/app_en.arb` — should see `"appTitle": "Bexly"`, `"home": "Home"`, etc.
- Open `lib/l10n/app_vi.arb` — should see `"appTitle": "Bexly"`, `"home": "Trang chủ"`, etc.
- Check that parameterized strings like `countPendingTransactions` have `@countPendingTransactions` metadata with `count` placeholder.

- [ ] **Step 4: Commit extracted arb files**
```bash
git add lib/l10n/ scripts/extract_arb.dart
git commit -m "chore(l10n): extract all strings to .arb files (14 languages)"
```

---

## Chunk 2: Code Generation & Integration

### Task 3: Run flutter gen-l10n and verify

**Files:**
- Creates: `lib/core/localization/generated/app_localizations.dart` (auto-generated)
- Creates: `lib/core/localization/generated/app_localizations_en.dart` etc.

- [ ] **Step 1: Run flutter pub get to fetch flutter_localizations**
```bash
flutter pub get
```

- [ ] **Step 2: Run gen-l10n**
```bash
flutter gen-l10n
```
Expected: No errors. Generated files appear in `lib/core/localization/generated/`.

- [ ] **Step 3: If errors — fix .arb files**
Common issues:
- Missing `@@locale` key → already handled in script
- Duplicate keys between en and other languages → check with `jq 'keys' lib/l10n/app_en.arb`
- Invalid ICU format → check parameterized strings

---

### Task 4: Extract business logic to utility class

The old `AppLocalizations` had 2 pieces of non-l10n logic that gen-l10n can't handle:
1. `minutesAgo(int count)` / `hoursAgo(int count)` — pluralization + language-specific format
2. `getCategoryName(int? categoryId)` — category ID→key→l10n lookup
3. `getByLocale(String lang, String key)` — background-service static access

**Files:**
- Create: `lib/core/localization/time_ago_l10n.dart`
- Create: `lib/core/localization/category_name_l10n.dart`

- [ ] **Step 1: Create time_ago_l10n.dart**

```dart
// lib/core/localization/time_ago_l10n.dart
import 'package:flutter/widgets.dart';
import 'package:bexly/core/localization/generated/app_localizations.dart';

extension TimeAgoL10n on AppLocalizations {
  String minutesAgo(int count) {
    // Vietnamese
    if (localeName == 'vi') return '$count phút trước';
    // English pluralization
    return count == 1 ? '1 minute ago' : '$count minutes ago';
  }

  String hoursAgo(int count) {
    if (localeName == 'vi') return '$count giờ trước';
    return count == 1 ? '1 hour ago' : '$count hours ago';
  }
}
```

- [ ] **Step 2: Create category_name_l10n.dart**

```dart
// lib/core/localization/category_name_l10n.dart
import 'package:bexly/core/localization/generated/app_localizations.dart';

extension CategoryNameL10n on AppLocalizations {
  static const Map<int, String Function(AppLocalizations)> _categoryGetters = {
    1: (l) => l.categoryFoodDrinks,
    2: (l) => l.categoryTransportation,
    3: (l) => l.categoryHousing,
    // ... (fill all IDs from the old _categoryIdToKey map)
  };

  String getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Unknown Category';
    final getter = _categoryGetters[categoryId];
    return getter?.call(this) ?? 'Unknown Category';
  }
}
```

> **Note:** Fill all ~50 category ID entries from `_categoryIdToKey` in the old file.

- [ ] **Step 3: Handle getByLocale for background services**

In background services that used `AppLocalizations.getByLocale(lang, key)`:
- Search for usages: `grep -rn "getByLocale" lib/`
- Replace with: create a `AppLocalizations` instance using `AppLocalizations.delegate.load(Locale(lang))` and call the getter directly.
- If too complex, keep a thin `BackgroundL10n` utility that wraps the generated delegate.

---

### Task 5: Update localization_extension.dart

**Files:**
- Modify: `lib/core/extensions/localization_extension.dart`
- Modify: `lib/core/localization/app_localizations.dart` → delete after migration

- [ ] **Step 1: Update import in localization_extension.dart**

Change:
```dart
import 'package:bexly/core/localization/app_localizations.dart';
```
To:
```dart
import 'package:bexly/core/localization/generated/app_localizations.dart';
```

The `context.l10n` getter remains `AppLocalizations.of(context)!` — the generated class has the same `of(context)` factory, so no change needed.

- [ ] **Step 2: Update MaterialApp (or wherever localizations are configured)**

Find `MaterialApp` in `main.dart` or equivalent. Currently uses custom `AppLocalizationsDelegate`. Replace with:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bexly/core/localization/generated/app_localizations.dart';

// In MaterialApp:
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

- [ ] **Step 3: Run flutter analyze**
```bash
flutter analyze 2>&1 | grep -E "error:|warning:" | head -30
```
Fix any import errors (replace old `app_localizations.dart` imports with `generated/app_localizations.dart`).

- [ ] **Step 4: Search and replace all imports**
```bash
grep -rn "core/localization/app_localizations" lib/ --include="*.dart" -l
```
For each file found, change the import to `generated/app_localizations.dart`.

---

### Task 6: Add missing strings for recurring screen and remove old file

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Delete: `lib/core/localization/app_localizations.dart` (old custom file)

- [ ] **Step 1: Add new recurring-related strings to app_en.arb**

Add to `lib/l10n/app_en.arb`:
```json
"dueToday": "Today",
"overdue": "Overdue",
"dueInDays": "Due in {days} days",
"@dueInDays": {
  "placeholders": {
    "days": {"type": "int"}
  }
},
"frequencyDaily": "Daily",
"frequencyWeekly": "Weekly",
"frequencyMonthly": "Monthly",
"frequencyQuarterly": "Quarterly",
"frequencyYearly": "Yearly",
"frequencyCustom": "Custom",
"aiDetectedRecurring": "AI detected {count} recurring patterns",
"@aiDetectedRecurring": {
  "placeholders": {
    "count": {"type": "int"}
  }
}
```

- [ ] **Step 2: Add Vietnamese translations to app_vi.arb**
```json
"dueToday": "Hôm nay",
"overdue": "Quá hạn",
"dueInDays": "Còn {days} ngày",
"frequencyDaily": "Hàng ngày",
"frequencyWeekly": "Hàng tuần",
"frequencyMonthly": "Hàng tháng",
"frequencyQuarterly": "Hàng quý",
"frequencyYearly": "Hàng năm",
"frequencyCustom": "Tùy chỉnh",
"aiDetectedRecurring": "AI phát hiện {count} khoản định kỳ"
```

- [ ] **Step 3: Re-run flutter gen-l10n**
```bash
flutter gen-l10n
```

- [ ] **Step 4: Update recurring_card.dart to use context.l10n**

Change `RecurringCard` to `HookConsumerWidget` (or pass context), then:
```dart
// Badge text:
isOverdue
    ? context.l10n.overdue
    : isDueToday
        ? context.l10n.dueToday
        : context.l10n.dueInDays(daysUntilDue)
```

- [ ] **Step 5: Update recurring_enums.dart**

Remove `displayName` hardcoded strings from enum (can't use context in enum).
Add a `BuildContext`-aware helper in `RecurringCard` or a separate extension:
```dart
extension RecurringFrequencyDisplay on RecurringFrequency {
  String localizedName(BuildContext context) {
    switch (this) {
      case RecurringFrequency.daily: return context.l10n.frequencyDaily;
      case RecurringFrequency.weekly: return context.l10n.frequencyWeekly;
      case RecurringFrequency.monthly: return context.l10n.frequencyMonthly;
      case RecurringFrequency.quarterly: return context.l10n.frequencyQuarterly;
      case RecurringFrequency.yearly: return context.l10n.frequencyYearly;
      case RecurringFrequency.custom: return context.l10n.frequencyCustom;
    }
  }
}
```
Update `RecurringCard` to use `recurring.frequency.localizedName(context)` instead of `recurring.frequency.displayName`.

- [ ] **Step 6: Update recurring_screen.dart**
```dart
context.l10n.aiDetectedRecurring(suggestions.length)
```

- [ ] **Step 7: Delete old app_localizations.dart**
```bash
git rm lib/core/localization/app_localizations.dart
```

- [ ] **Step 8: Run full analyze**
```bash
flutter analyze 2>&1 | grep "error:" | head -30
```
Fix all remaining errors.

- [ ] **Step 9: Final commit**
```bash
git add lib/l10n/ lib/core/localization/ lib/features/recurring/ scripts/
git commit -m "feat(l10n): migrate to flutter gen-l10n with .arb files

- Replace 6553-line custom AppLocalizations with flutter gen-l10n
- 14 languages extracted to lib/l10n/*.arb
- context.l10n.xxx API unchanged — no call-sites modified
- minutesAgo/hoursAgo moved to TimeAgoL10n extension
- getCategoryName moved to CategoryNameL10n extension
- Recurring screen now uses l10n strings (dueInDays, frequencyMonthly, etc.)
"
```

---

## Risk Notes

- **Call-sites unchanged**: All `context.l10n.xxx` getters keep same names → zero call-site edits needed for simple strings.
- **Parameterized strings**: Old code used `replaceAll('{count}', ...)` — new generated code uses typed method args `l10n.countPendingTransactions(5)` — same interface, just typed.
- **Background services**: `AppLocalizations.getByLocale(lang, key)` pattern must be replaced. Check usages first.
- **minutesAgo/hoursAgo pluralization**: Moved to extension — callers remain unchanged since `context.l10n.minutesAgo(5)` still works via the extension.
- **Enum displayName**: Cannot use context in enum getter — need `localizedName(context)` extension method and update all callers.
