// scripts/extract_arb.dart
// Extracts all strings from lib/core/localization/app_localizations.dart
// and writes one .arb file per language to lib/l10n/app_<lang>.arb
//
// Run with: dart run scripts/extract_arb.dart

import 'dart:io';
import 'dart:convert';

void main() {
  final src = File('lib/core/localization/app_localizations.dart')
      .readAsStringSync();

  final languages = [
    'en', 'vi', 'zh', 'fr', 'th', 'id', 'es', 'pt', 'ja', 'ko', 'de', 'hi',
    'ru', 'ar'
  ];

  for (final lang in languages) {
    final map = _extractLanguageMap(src, lang);
    if (map.isEmpty) {
      print('⚠️  No entries found for $lang, skipping.');
      continue;
    }

    // Build ARB — @@locale first
    final arb = <String, dynamic>{'@@locale': lang};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      arb[key] = value;

      // Add @key metadata for placeholders
      final placeholders = _extractPlaceholders(value);
      if (placeholders.isNotEmpty) {
        arb['@$key'] = {
          'placeholders': {
            for (final p in placeholders)
              p: {'type': (p == 'count' || p == 'days') ? 'int' : 'String'},
          },
        };
      }
    }

    final output = const JsonEncoder.withIndent('  ').convert(arb);
    File('lib/l10n/app_$lang.arb').writeAsStringSync('$output\n');
    print('✅  lib/l10n/app_$lang.arb — ${map.length} strings');
  }
}

/// Extracts {key: value} map for the given language block.
/// Handles single-quoted Dart strings, including escaped quotes.
Map<String, String> _extractLanguageMap(String src, String lang) {
  // Find the language block start: 'lang': {
  final startMarker = "'$lang': {";
  final startIdx = src.indexOf(startMarker);
  if (startIdx == -1) return {};

  // Find the opening brace of the map
  final braceIdx = src.indexOf('{', startIdx + startMarker.length - 1);
  if (braceIdx == -1) return {};

  // Walk forward tracking brace depth to find the closing brace
  var depth = 0;
  var i = braceIdx;
  var blockEnd = -1;
  while (i < src.length) {
    final ch = src[i];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) {
        blockEnd = i;
        break;
      }
    }
    i++;
  }
  if (blockEnd == -1) return {};

  final block = src.substring(braceIdx + 1, blockEnd);
  return _parseStringMap(block);
}

/// Parse Dart-style map: 'key': 'value', pairs.
/// Handles escaped single quotes (\') inside values.
Map<String, String> _parseStringMap(String block) {
  final result = <String, String>{};
  var pos = 0;

  while (pos < block.length) {
    // Find start of key (single quote)
    final keyStart = block.indexOf("'", pos);
    if (keyStart == -1) break;

    // Find end of key
    final keyEnd = block.indexOf("'", keyStart + 1);
    if (keyEnd == -1) break;

    final key = block.substring(keyStart + 1, keyEnd);
    pos = keyEnd + 1;

    // Skip whitespace and colon
    final colonIdx = block.indexOf(':', pos);
    if (colonIdx == -1) break;
    pos = colonIdx + 1;

    // Skip whitespace
    while (pos < block.length && (block[pos] == ' ' || block[pos] == '\t')) {
      pos++;
    }

    // Read quoted value (handles \' escapes)
    if (pos >= block.length || block[pos] != "'") continue;
    pos++; // skip opening quote

    final valueBuf = StringBuffer();
    while (pos < block.length) {
      final ch = block[pos];
      if (ch == '\\' && pos + 1 < block.length) {
        final next = block[pos + 1];
        if (next == "'") {
          valueBuf.write("'");
          pos += 2;
          continue;
        } else if (next == 'n') {
          valueBuf.write('\n');
          pos += 2;
          continue;
        } else if (next == '\\') {
          valueBuf.write('\\');
          pos += 2;
          continue;
        }
      }
      if (ch == "'") {
        pos++; // skip closing quote
        break;
      }
      valueBuf.write(ch);
      pos++;
    }

    // Only store if key looks like a valid identifier
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(key)) {
      result[key] = valueBuf.toString();
    }
  }

  return result;
}

/// Extract {placeholder} names from a string value.
List<String> _extractPlaceholders(String value) {
  final regex = RegExp(r'\{(\w+)\}');
  return regex
      .allMatches(value)
      .map((m) => m.group(1)!)
      .toSet()
      .toList();
}
