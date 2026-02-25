// XP level definitions and calculation utilities for gamification module.
// Phase 0: static data only. Phase 2 will connect to real DB.

const List<({int level, String name, int xpRequired})> kLevelTable = [
  (level: 1,  name: 'Newcomer',        xpRequired: 0),
  (level: 2,  name: 'Tracker',         xpRequired: 50),
  (level: 3,  name: 'Planner',         xpRequired: 150),
  (level: 4,  name: 'Saver',           xpRequired: 300),
  (level: 5,  name: 'Strategist',      xpRequired: 500),
  (level: 6,  name: 'Budget Pro',      xpRequired: 800),
  (level: 7,  name: 'Finance Manager', xpRequired: 1200),
  (level: 8,  name: 'Finance Expert',  xpRequired: 1800),
  (level: 9,  name: 'Finance Master',  xpRequired: 2500),
  (level: 10, name: 'Finance Legend',  xpRequired: 3500),
];

/// Returns the level record for a given total XP.
({int level, String name, int xpRequired}) levelFromXp(int totalXp) {
  var current = kLevelTable.first;
  for (final entry in kLevelTable) {
    if (totalXp >= entry.xpRequired) {
      current = entry;
    } else {
      break;
    }
  }
  return current;
}

/// Returns the next level record, or null if already max level.
({int level, String name, int xpRequired})? nextLevel(int totalXp) {
  final current = levelFromXp(totalXp);
  final idx = kLevelTable.indexWhere((e) => e.level == current.level);
  if (idx == -1 || idx + 1 >= kLevelTable.length) return null;
  return kLevelTable[idx + 1];
}

/// Returns progress fraction (0.0–1.0) toward the next level.
double xpProgressFraction(int totalXp) {
  final current = levelFromXp(totalXp);
  final next = nextLevel(totalXp);
  if (next == null) return 1.0; // max level
  final range = next.xpRequired - current.xpRequired;
  final earned = totalXp - current.xpRequired;
  if (range <= 0) return 1.0;
  return (earned / range).clamp(0.0, 1.0);
}
