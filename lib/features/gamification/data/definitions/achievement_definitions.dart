enum AchievementCategory { recording, budget, savings, streak, exploration }

enum AchievementTier { bronze, silver, gold }

/// Static definition of an achievement (not stored in DB).
/// Only unlocked instances are stored.
class AchievementDef {
  final String key;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final int xpReward;
  final int bexReward;
  final String emoji;

  const AchievementDef({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.xpReward,
    required this.bexReward,
    required this.emoji,
  });
}

/// All 15 achievement definitions for Phase 1.
const List<AchievementDef> kAchievements = [
  // --- Recording ---
  AchievementDef(
    key: 'first_transaction',
    title: 'First Step',
    description: 'Record your first transaction.',
    category: AchievementCategory.recording,
    tier: AchievementTier.bronze,
    xpReward: 10,
    bexReward: 1,
    emoji: '📝',
  ),
  AchievementDef(
    key: 'fifty_transactions',
    title: 'Diligent',
    description: 'Record 50 transactions.',
    category: AchievementCategory.recording,
    tier: AchievementTier.silver,
    xpReward: 50,
    bexReward: 5,
    emoji: '✍️',
  ),
  AchievementDef(
    key: 'century_transactions',
    title: 'Record Master',
    description: 'Record 100 transactions.',
    category: AchievementCategory.recording,
    tier: AchievementTier.gold,
    xpReward: 100,
    bexReward: 15,
    emoji: '🏆',
  ),

  // --- Streak ---
  AchievementDef(
    key: 'streak_7',
    title: 'Perfect Week',
    description: 'Record transactions 7 days in a row.',
    category: AchievementCategory.streak,
    tier: AchievementTier.bronze,
    xpReward: 25,
    bexReward: 3,
    emoji: '🔥',
  ),
  AchievementDef(
    key: 'streak_30',
    title: 'Disciplined Month',
    description: 'Record transactions 30 days in a row.',
    category: AchievementCategory.streak,
    tier: AchievementTier.silver,
    xpReward: 100,
    bexReward: 10,
    emoji: '⚡',
  ),
  AchievementDef(
    key: 'streak_100',
    title: 'Unstoppable',
    description: 'Record transactions 100 days in a row.',
    category: AchievementCategory.streak,
    tier: AchievementTier.gold,
    xpReward: 300,
    bexReward: 30,
    emoji: '💎',
  ),

  // --- Budget ---
  AchievementDef(
    key: 'first_budget',
    title: 'The Planner',
    description: 'Create your first budget.',
    category: AchievementCategory.budget,
    tier: AchievementTier.bronze,
    xpReward: 15,
    bexReward: 2,
    emoji: '📊',
  ),
  AchievementDef(
    key: 'budget_keeper',
    title: 'Budget Keeper',
    description: 'Stay within budget for a full month.',
    category: AchievementCategory.budget,
    tier: AchievementTier.silver,
    xpReward: 50,
    bexReward: 8,
    emoji: '🎯',
  ),
  AchievementDef(
    key: 'budget_master',
    title: 'Budget Master',
    description: 'Stay within budget for 3 months in a row.',
    category: AchievementCategory.budget,
    tier: AchievementTier.gold,
    xpReward: 150,
    bexReward: 20,
    emoji: '👑',
  ),

  // --- Savings ---
  AchievementDef(
    key: 'first_goal',
    title: 'Goal Setter',
    description: 'Create your first savings goal.',
    category: AchievementCategory.savings,
    tier: AchievementTier.bronze,
    xpReward: 15,
    bexReward: 2,
    emoji: '🌱',
  ),
  AchievementDef(
    key: 'goal_halfway',
    title: 'Halfway There',
    description: 'Reach 50% of a savings goal.',
    category: AchievementCategory.savings,
    tier: AchievementTier.silver,
    xpReward: 50,
    bexReward: 5,
    emoji: '🚀',
  ),
  AchievementDef(
    key: 'goal_achieved',
    title: 'Goal Achieved',
    description: 'Complete your first savings goal.',
    category: AchievementCategory.savings,
    tier: AchievementTier.gold,
    xpReward: 200,
    bexReward: 25,
    emoji: '🌟',
  ),

  // --- Exploration ---
  AchievementDef(
    key: 'first_category',
    title: 'Organized',
    description: 'Create a custom category.',
    category: AchievementCategory.exploration,
    tier: AchievementTier.bronze,
    xpReward: 10,
    bexReward: 1,
    emoji: '🗂️',
  ),
  AchievementDef(
    key: 'multi_wallet',
    title: 'Multi Wallet',
    description: 'Create 3 or more wallets.',
    category: AchievementCategory.exploration,
    tier: AchievementTier.silver,
    xpReward: 25,
    bexReward: 3,
    emoji: '👛',
  ),
  AchievementDef(
    key: 'ai_chat_first',
    title: 'AI Friend',
    description: 'Chat with the AI assistant for the first time.',
    category: AchievementCategory.exploration,
    tier: AchievementTier.bronze,
    xpReward: 10,
    bexReward: 1,
    emoji: '🤖',
  ),
];

/// Mock: keys of achievements already unlocked (Phase 0 — replace with DB in Phase 1)
const Set<String> kMockUnlockedKeys = {
  'first_transaction',
  'streak_7',
  'first_budget',
};

/// Total BEX earned from mock unlocked achievements
int get kMockTotalBex => kAchievements
    .where((a) => kMockUnlockedKeys.contains(a.key))
    .fold(0, (sum, a) => sum + a.bexReward);
