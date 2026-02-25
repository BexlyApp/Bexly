import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/buttons/button_chip.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/gamification/data/definitions/achievement_definitions.dart';
import 'package:bexly/features/gamification/utils/xp_calculator.dart';

// Phase 0: mock data — replace with real providers in Phase 1.
const int _mockTotalXp = 420;
const int _mockStreakDays = 7;
const int _mockStreakRecord = 14;

const _streakMilestones = [
  (days: 7, bex: 3, label: 'Perfect Week'),
  (days: 30, bex: 10, label: 'Disciplined Month'),
  (days: 100, bex: 30, label: 'Unstoppable'),
];

class GamificationProfileScreen extends HookWidget {
  const GamificationProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);
    final filterIndex = useState<int>(0);

    final current = levelFromXp(_mockTotalXp);
    final progress = xpProgressFraction(_mockTotalXp);
    final totalBex = kMockTotalBex;

    final categories = [
      null,
      AchievementCategory.recording,
      AchievementCategory.streak,
      AchievementCategory.budget,
      AchievementCategory.savings,
      AchievementCategory.exploration,
    ];
    final categoryLabels = ['All', 'Recording', 'Streak', 'Budget', 'Savings', 'Explore'];

    final filtered = categories[filterIndex.value] == null
        ? kAchievements
        : kAchievements.where((a) => a.category == categories[filterIndex.value]).toList();

    final unlockedCount = kAchievements.where((a) => kMockUnlockedKeys.contains(a.key)).length;

    return CustomScaffold(
      context: context,
      title: 'Quests & Rewards',
      showBalance: false,
      body: Column(
        children: [
          // ── BEX + Level header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing20,
              AppSpacing.spacing16,
              AppSpacing.spacing20,
              AppSpacing.spacing16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // BEX balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BEX Balance',
                        style: AppTextStyles.body4.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.spacing4),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAlpha10,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('⚡', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const Gap(AppSpacing.spacing8),
                          Text(
                            '$totalBex BEX',
                            style: AppTextStyles.heading4.copyWith(
                              color: AppColors.primary600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16,
                    vertical: AppSpacing.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAlpha10,
                    border: Border.all(color: AppColors.primaryAlpha25),
                    borderRadius: BorderRadius.circular(AppRadius.radius16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lv.${current.level}',
                            style: AppTextStyles.body3.copyWith(
                              color: AppColors.primary600,
                            ),
                          ),
                          const Gap(AppSpacing.spacing4),
                          Text(
                            current.name,
                            style: AppTextStyles.body4.copyWith(
                              color: AppColors.primary700,
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.spacing4),
                      SizedBox(
                        width: 96,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.primaryAlpha10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary600),
                          ),
                        ),
                      ),
                      const Gap(AppSpacing.spacing2),
                      Text(
                        '$_mockTotalXp XP',
                        style: AppTextStyles.body5.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── TabBar ─────────────────────────────────────────────────────
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary600,
              indicatorWeight: 3,
              labelColor: AppColors.primary600,
              unselectedLabelColor: AppColors.neutral400,
              labelStyle: AppTextStyles.body3,
              unselectedLabelStyle: AppTextStyles.body3,
              tabs: const [
                Tab(text: 'Quests'),
                Tab(text: 'Streak'),
              ],
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // ── Quests Tab ─────────────────────────────────────────
                CustomScrollView(
                  slivers: [
                    // Stats row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.spacing20,
                          AppSpacing.spacing12,
                          AppSpacing.spacing20,
                          AppSpacing.spacing8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$unlockedCount / ${kAchievements.length} completed',
                              style: AppTextStyles.body3.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAlpha10,
                                border: Border.all(color: AppColors.primaryAlpha25),
                                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                              ),
                              child: Row(
                                children: [
                                  const Text('⚡', style: TextStyle(fontSize: 12)),
                                  const Gap(AppSpacing.spacing4),
                                  Text(
                                    '$totalBex BEX earned',
                                    style: AppTextStyles.body4.copyWith(
                                      color: AppColors.primary600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Filter chips — use ButtonChip component
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
                          itemCount: categoryLabels.length,
                          separatorBuilder: (context, i) => const Gap(AppSpacing.spacing8),
                          itemBuilder: (context, i) => ButtonChip(
                            label: categoryLabels[i],
                            active: filterIndex.value == i,
                            onTap: () => filterIndex.value = i,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: Gap(AppSpacing.spacing12)),

                    // Achievement grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final def = filtered[i];
                            final isUnlocked = kMockUnlockedKeys.contains(def.key);
                            return _QuestCard(def: def, isUnlocked: isUnlocked);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: Gap(AppSpacing.spacing32)),
                  ],
                ),

                // ── Streak Tab ─────────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.spacing20),
                  children: [
                    _StreakCurrentCard(
                      streakDays: _mockStreakDays,
                      streakRecord: _mockStreakRecord,
                    ),
                    const Gap(AppSpacing.spacing12),
                    _StreakInfoCard(),
                    const Gap(AppSpacing.spacing12),
                    _StreakMilestonesCard(currentStreak: _mockStreakDays),
                    const Gap(AppSpacing.spacing32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quest Card
// ---------------------------------------------------------------------------

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.def, required this.isUnlocked});

  final AchievementDef def;
  final bool isUnlocked;

  Color _tierColor(AchievementTier tier) {
    return switch (tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silver => const Color(0xFF9E9E9E),
      AchievementTier.gold => const Color(0xFFFFB300),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tierColor = _tierColor(def.tier);

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.primaryAlpha10
            : cs.surfaceContainerLow,
        border: Border.all(
          color: isUnlocked ? AppColors.primaryAlpha25 : cs.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji / lock icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? tierColor.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.radius12),
                border: isUnlocked
                    ? Border.all(color: tierColor.withValues(alpha: 0.3))
                    : null,
              ),
              child: Center(
                child: isUnlocked
                    ? Text(def.emoji, style: const TextStyle(fontSize: 24))
                    : Icon(Icons.lock_outline_rounded, size: 20, color: cs.outline),
              ),
            ),
            const Gap(8),
            Text(
              def.title,
              style: AppTextStyles.body4.copyWith(
                color: isUnlocked ? cs.onSurface : cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            // BEX reward badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isUnlocked ? AppColors.primaryAlpha10 : cs.surfaceContainerHighest,
                border: Border.all(
                  color: isUnlocked ? AppColors.primaryAlpha25 : cs.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚡',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUnlocked ? null : cs.onSurfaceVariant,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '+${def.bexReward}',
                    style: AppTextStyles.body5.copyWith(
                      color: isUnlocked ? AppColors.primary700 : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak Tab Widgets
// ---------------------------------------------------------------------------

class _StreakCurrentCard extends StatelessWidget {
  const _StreakCurrentCard({required this.streakDays, required this.streakRecord});

  final int streakDays;
  final int streakRecord;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeDots = streakDays.clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.redAlpha10,
                  borderRadius: BorderRadius.circular(AppRadius.radius12),
                ),
                child: const Center(child: Text('🔥', style: TextStyle(fontSize: 22))),
              ),
              const Gap(AppSpacing.spacing16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streakDays-day streak', style: AppTextStyles.body1),
                  Text(
                    'Best: $streakRecord days',
                    style: AppTextStyles.body4.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const Gap(AppSpacing.spacing16),
          Text(
            'This week',
            style: AppTextStyles.body4.copyWith(color: cs.onSurfaceVariant),
          ),
          const Gap(AppSpacing.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isActive = i < activeDots;
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryAlpha10 : cs.surfaceContainerHighest,
                      border: Border.all(
                        color: isActive ? AppColors.primaryAlpha25 : cs.outlineVariant,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isActive
                          ? const Text('🔥', style: TextStyle(fontSize: 16))
                          : null,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _days[i],
                    style: AppTextStyles.body5.copyWith(
                      color: isActive ? AppColors.primary600 : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StreakInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary600),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Text(
              'Record at least one transaction each day to keep your streak alive. Reach milestones to earn BEX rewards.',
              style: AppTextStyles.body4.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakMilestonesCard extends StatelessWidget {
  const _StreakMilestonesCard({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: AppTextStyles.body2.copyWith(color: cs.onSurface),
          ),
          const Gap(AppSpacing.spacing16),
          ..._streakMilestones.map((m) {
            final isReached = currentStreak >= m.days;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isReached ? AppColors.primaryAlpha10 : cs.surfaceContainerHighest,
                      border: Border.all(
                        color: isReached ? AppColors.primaryAlpha25 : cs.outlineVariant,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isReached
                          ? Icon(Icons.check_rounded, size: 16, color: AppColors.primary600)
                          : Icon(Icons.lock_outline_rounded, size: 14, color: cs.outline),
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: AppTextStyles.body3.copyWith(
                            color: isReached ? cs.onSurface : cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${m.days} days in a row',
                          style: AppTextStyles.body4.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isReached ? AppColors.primaryAlpha10 : cs.surfaceContainerHighest,
                      border: Border.all(
                        color: isReached ? AppColors.primaryAlpha25 : cs.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const Gap(AppSpacing.spacing4),
                        Text(
                          '+${m.bex} BEX',
                          style: AppTextStyles.body4.copyWith(
                            color: isReached ? AppColors.primary700 : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
