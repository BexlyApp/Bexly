# Gamification Module Plan

## Overview

Module gamification tăng user engagement và retention thông qua streaks, achievements, XP/levels và challenges. Thiết kế tinh tế, opt-in/opt-out, chỉ reward hành vi tài chính tốt.

**Phases:**
- Phase 0 (quick win): Confetti + progress bar màu cho goals/budgets
- Phase 1 (MVP): Streaks + 15 achievements + dashboard widget
- Phase 2: XP/Levels + challenges + monthly report card
- Phase 3: Seasonal challenges + family challenges + AI chat integration

**Design Principles:**
1. Only reward good financial behavior (recording, budgeting, saving). NEVER reward spending.
2. Subtle, not flashy — small streak card, confetti only for big milestones.
3. Opt-in/opt-out toggle in Settings.
4. Bottom sheet only for unlock notifications (no AlertDialog per UI rule).
5. Gentle Vietnamese tone, not "CONGRATULATIONS!!!" American style.
6. Offline-first — all evaluation logic runs locally.

---

## Database Layer

### Local Drift Tables

**`lib/core/database/tables/user_streak_table.dart`** (Phase 1)
```dart
@DataClassName('UserStreakEntry')
class UserStreaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get streakType => text()();            // "recording", "budget", "login"
  IntColumn get currentCount => integer()
      .withDefault(const Constant(0))();
  IntColumn get longestCount => integer()
      .withDefault(const Constant(0))();
  DateTimeColumn get lastRecordedDate => dateTime().nullable()();
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

**`lib/core/database/tables/user_achievement_table.dart`** (Phase 1)
```dart
@DataClassName('UserAchievementEntry')
class UserAchievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get achievementKey => text()();        // "first_transaction", "streak_7"
  IntColumn get xpEarned => integer()
      .withDefault(const Constant(0))();
  DateTimeColumn get unlockedAt => dateTime()();
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

**`lib/core/database/tables/gamification_profile_table.dart`** (Phase 2)
```dart
@DataClassName('GamificationProfileEntry')
class GamificationProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  IntColumn get totalXp => integer()
      .withDefault(const Constant(0))();
  IntColumn get level => integer()
      .withDefault(const Constant(1))();
  BoolColumn get gamificationEnabled => boolean()
      .withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

**`lib/core/database/tables/challenge_table.dart`** (Phase 2)
```dart
@DataClassName('ChallengeEntry')
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().nullable().unique()();
  TextColumn get challengeKey => text()();          // "no_spend_day", "category_limit"
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get criteriaJson => text()();          // JSON config
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get status => text()                   // "active", "completed", "failed"
      .withDefault(const Constant('active'))();
  IntColumn get xpReward => integer()
      .withDefault(const Constant(50))();
  BoolColumn get isDeleted => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
```

### Supabase Cloud Tables (schema `bexly`)

```sql
-- Phase 1
CREATE TABLE bexly.user_streaks (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    streak_type TEXT NOT NULL,
    current_count INTEGER NOT NULL DEFAULT 0,
    longest_count INTEGER NOT NULL DEFAULT 0,
    last_recorded_date TIMESTAMPTZ,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bexly.user_achievements (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    achievement_key TEXT NOT NULL,
    xp_earned INTEGER NOT NULL DEFAULT 0,
    unlocked_at TIMESTAMPTZ NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Phase 2
CREATE TABLE bexly.gamification_profiles (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
    total_xp INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    gamification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bexly.challenges (
    cloud_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    challenge_key TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    criteria_json TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    xp_reward INTEGER NOT NULL DEFAULT 50,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE bexly.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.gamification_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bexly.challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users own streaks" ON bexly.user_streaks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own achievements" ON bexly.user_achievements FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own profile" ON bexly.gamification_profiles FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own challenges" ON bexly.challenges FOR ALL USING (auth.uid() = user_id);
```

---

## Achievement Definitions (Static Code — Not in DB)

Only user's unlocked achievements go to DB. Definitions are static constants.

**`lib/features/gamification/data/definitions/achievement_definitions.dart`**

```dart
enum AchievementCategory { recording, budget, savings, streak, exploration }
enum AchievementTier { bronze, silver, gold, platinum }
```

### Phase 1: 15 Achievements

| Key | Title (VI) | Title (EN) | Tier | XP | Criteria |
|-----|-----------|-----------|------|-----|----------|
| `first_transaction` | Bước đầu tiên | First Step | Bronze | 10 | 1 transaction |
| `fifty_transactions` | Siêng năng | Diligent | Silver | 50 | 50 transactions |
| `century_transactions` | Bậc thầy ghi chép | Record Master | Gold | 100 | 100 transactions |
| `streak_7` | Tuần hoàn hảo | Perfect Week | Bronze | 25 | 7-day streak |
| `streak_30` | Tháng kỷ luật | Disciplined Month | Silver | 100 | 30-day streak |
| `streak_100` | Bền bỉ | Unstoppable | Gold | 300 | 100-day streak |
| `first_budget` | Nhà hoạch định | The Planner | Bronze | 15 | Create 1 budget |
| `budget_keeper` | Giữ ngân sách | Budget Keeper | Silver | 50 | Stay within budget 1 month |
| `budget_master` | Bậc thầy ngân sách | Budget Master | Gold | 150 | Stay within budget 3 months |
| `first_goal` | Có mục tiêu | Goal Setter | Bronze | 15 | Create 1 goal |
| `goal_halfway` | Nửa đường | Halfway There | Silver | 50 | Reach 50% of a goal |
| `goal_achieved` | Thành tựu | Goal Achieved | Gold | 200 | Complete first goal |
| `first_category` | Tổ chức | Organized | Bronze | 10 | Create 1 custom category |
| `multi_wallet` | Đa ví | Multi Wallet | Silver | 25 | Create 3+ wallets |
| `ai_chat_first` | Bạn AI | AI Friend | Bronze | 10 | Chat with AI once |

---

## Achievement Evaluation Engine

**Pattern: Event-driven — hooks into existing DAOs**

```
Trigger Points:
├── After transaction insert → check: transaction_count, streak update
├── After budget period end → check: budget_adherence
├── After goal update       → check: goal_progress, goal_completed
├── After category create   → check: custom_category_count
├── After wallet create     → check: wallet_count
├── After AI chat message   → check: ai_chat_count
└── On app open (daily)     → check: streak continuity
```

### Streak Logic
```
recordActivity(type, date):
  1. Get current streak for type
  2. If lastRecordedDate == today → no-op
  3. If lastRecordedDate == yesterday → currentCount++
  4. If lastRecordedDate < yesterday → currentCount = 1 (broken)
  5. Update longestCount = max(longestCount, currentCount)
  6. Save
```

### Integration Approach
```dart
// After existing transaction creation:
await transactionDao.createTransaction(tx);
// Hook:
await ref.read(achievementEvaluatorProvider).onTransactionCreated();
await ref.read(streakTrackerProvider).recordActivity('recording');
```

---

## Feature Module Structure

```
lib/features/gamification/
├── data/
│   ├── models/
│   │   ├── achievement_model.dart           # @freezed — unlocked achievement
│   │   ├── streak_model.dart                # @freezed — streak state
│   │   ├── gamification_profile_model.dart  # @freezed — XP/level (Phase 2)
│   │   └── challenge_model.dart             # @freezed — challenge (Phase 2)
│   ├── definitions/
│   │   └── achievement_definitions.dart     # Static const list
│   └── repositories/
│       └── gamification_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── achievements_screen.dart         # Grid of all badges
│   │   ├── streak_details_screen.dart       # Streak history + calendar
│   │   └── challenges_screen.dart           # Phase 2
│   ├── components/
│   │   ├── streak_card.dart                 # Dashboard: fire + count
│   │   ├── achievement_badge_widget.dart    # Single badge
│   │   ├── achievement_grid.dart            # Grid layout
│   │   ├── mini_achievements_row.dart       # Dashboard: latest 3
│   │   ├── level_progress_bar.dart          # Phase 2
│   │   └── challenge_card.dart              # Phase 2
│   ├── bottom_sheets/
│   │   └── achievement_unlocked_sheet.dart  # Bottom sheet on unlock
│   ├── animations/
│   │   └── confetti_overlay.dart
│   └── riverpod/
│       ├── streak_provider.dart
│       ├── achievements_provider.dart
│       ├── all_achievements_provider.dart
│       ├── achievement_evaluator_provider.dart
│       ├── gamification_profile_provider.dart  # Phase 2
│       └── challenges_provider.dart            # Phase 2
├── services/
│   ├── achievement_evaluator.dart
│   ├── streak_tracker.dart
│   ├── gamification_sync_service.dart
│   └── streak_notification_service.dart
└── utils/
    ├── xp_calculator.dart
    └── achievement_icons.dart
```

---

## UI Design

### Dashboard Integration
```
┌─ Dashboard ──────────────────────────
│  ├─ Balance Card v2 (existing)
│  ├─ [NEW] Streak Card               ← 🔥 7 ngày liên tiếp
│  ├─ Greeting Card (existing)
│  ├─ Cash Flow Cards (existing)
│  ├─ [NEW] Mini Achievements Row     ← Latest 3 unlocked (tap → full grid)
│  ├─ Spending Progress (existing)
│  └─ ...
```

### Achievement Unlocked Bottom Sheet
```
┌──────────────────────────────────────┐
│            ─── (drag handle)         │
│         🏆 (large badge icon)        │
│       "Tuần hoàn hảo" (title)        │
│   Ghi chép 7 ngày liên tiếp (desc)  │
│          +25 XP (reward)             │
│    [  Xem tất cả  ]  [  Đóng  ]     │
└──────────────────────────────────────┘
```

### Achievements Screen
```
┌─ Thành tựu ──────────────────────────
│  Header: "8/15 đã đạt" + XP bar
│  Filter: Tất cả | Ghi chép | Ngân sách | Tiết kiệm | Streaks
│  Grid (3 columns):
│     [🏆 color] First Step    ✓
│     [🏆 color] Perfect Week  ✓
│     [🔒 grey]  Disciplined Month
│     ...
```

### Streak Card (Dashboard)
```
┌──────────────────────────┐
│  🔥 7     Kỷ lục: 23    │
│  ngày liên tiếp          │
│  ░░░░░░░████████░░░░░░░  │  ← 7-day mini calendar dots
└──────────────────────────┘
```

---

## Settings Integration

```
├─ Settings Preferences Group
│  ├─ Language
│  ├─ Theme Mode
│  ├─ [NEW] Gamification ← Toggle on/off
│  │   ├─ Show streak on Dashboard
│  │   ├─ Show achievements
│  │   └─ Streak reminder notifications
│  ├─ Currency
│  └─ Number format
```

---

## Notification

```
Daily at 21:00 if no transaction recorded today:
"Đừng quên ghi chép hôm nay! Streak hiện tại: 7 ngày 🔥"

Only if: gamification enabled, streak > 0, no transaction today.
Uses existing flutter_local_notifications.
```

---

## Routes

```dart
static const String achievements = '/achievements';
static const String streakDetails = '/streak-details';
static const String challenges = '/challenges';          // Phase 2
```

---

## Dependencies

```yaml
# Phase 0
confetti_widget: ^0.4.0    # Confetti for goal + badge unlock

# Phase 1+ — no new deps needed
# Uses existing: lottie, flutter_local_notifications, hugeicons, fl_chart
```

---

## Phase Breakdown

### Phase 0 — Quick Wins (~2-3 days)
1. Add `confetti_widget` package
2. Confetti animation when goal completed
3. Color-coded progress bar for budgets
4. No schema changes needed

### Phase 1 — MVP Gamification (~2-3 weeks)
1. Drift tables: `user_streaks`, `user_achievements` + migration
2. `StreakModel`, `AchievementModel` (@freezed)
3. Static `achievement_definitions.dart` (15 achievements)
4. `AchievementEvaluator` + `StreakTracker` services
5. `StreakDao`, `AchievementDao`
6. Riverpod providers
7. UI: streak_card, mini_achievements_row on dashboard
8. UI: achievements_screen (full grid)
9. UI: achievement_unlocked_sheet (bottom sheet)
10. Settings toggle
11. Streak notification (21:00 daily)
12. Supabase migration + sync
13. Routes + navigation

### Phase 2 — XP & Challenges (~2-3 weeks after Phase 1)
1. Drift tables: `gamification_profiles`, `challenges` + migration
2. XP calculation + level thresholds
3. Level progress bar on achievements screen
4. Predefined challenges: "Ngày zero", "Tuần tiết kiệm", "Thử thách danh mục"
5. Challenge UI + progress tracking
6. Monthly report card (summary bottom sheet)
7. Supabase migration + sync

### Phase 3 — Social & AI (~3-4 weeks after Phase 2)
1. Seasonal challenges (Tết, summer...)
2. Family challenges (using existing family_groups)
3. Family streak leaderboard
4. AI chat integration: congratulate achievements, suggest challenges
5. Premium tier: advanced badges, custom themes
