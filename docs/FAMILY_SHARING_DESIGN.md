# Family Sharing Feature - Design Document

## Overview

Family Sharing allows multiple users to share wallets and track expenses together within a "Family Group". Each member has their own account, can be invited to join, and has role-based permissions.

## Key Features

- **Max 5 members** per family
- **Role-based permissions**: Owner, Editor, Viewer
- **Selective wallet sharing** - choose which wallets to share
- **Track transaction authorship** - know who created each transaction
- **Two workspaces**: Personal vs Family/Shared
- **Premium feature** - Family tier (~$5.99-6.99/month)

---

## User Experience

### Workspace Concept

Users have two distinct workspaces:

```
┌─────────────────────────────────────────┐
│  [Personal]  │  [Family]               │  ← Tab Switcher
├─────────────────────────────────────────┤
│                                         │
│  PERSONAL WALLETS                       │
│  ├─ 💰 My Cash           $1,500        │
│  ├─ 🏦 My Bank           $3,200        │
│  └─ 💳 My Credit Card    -$500         │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  SHARED WALLETS (Family view only)      │
│  ├─ 🏠 Household         $2,000        │
│  │     Joy: $800 | Wife: $1,200        │
│  └─ 🎉 Vacation Fund     $5,000        │
│                                         │
└─────────────────────────────────────────┘
```

**Personal Workspace:**
- All user's own wallets
- Private transactions
- Only visible to the user

**Family Workspace:**
- Shared wallets only
- Transactions from all family members
- Shows who created each transaction
- Shows individual contributions

### Invitation Flow

#### Owner Invites Member

```
┌────────────────────────────────────┐
│       Invite to Family             │
├────────────────────────────────────┤
│                                    │
│ Email:                             │
│ ┌────────────────────────────────┐ │
│ │ wife@email.com                 │ │
│ └────────────────────────────────┘ │
│                                    │
│ Role:                              │
│ ○ Editor (can add/edit)            │
│ ● Viewer (view only)               │
│                                    │
│ ┌────────────────────────────────┐ │
│ │      Send Invitation           │ │
│ └────────────────────────────────┘ │
│                                    │
│ ─────────── OR ───────────         │
│                                    │
│ Share invite link:                 │
│ ┌────────────────────────────────┐ │
│ │ join.bexly.app/f/joyng         │ │
│ │              [Copy] [Share]    │ │
│ └────────────────────────────────┘ │
│                                    │
│ Invite code (7 days):              │
│ join.bexly.app/f/X7K9M2P          │
│                                    │
└────────────────────────────────────┘
```

#### Invitee Accepts

```
┌────────────────────────────────────┐
│      Family Invitation 👨‍👩‍👧‍👦         │
├────────────────────────────────────┤
│                                    │
│ Joy invited you to join            │
│ "Nguyen Family"                    │
│                                    │
│ Role: Editor                       │
│ Members: 2/5                       │
│                                    │
│ ┌──────────┐  ┌────────────────┐   │
│ │ Decline  │  │   Accept ✓     │   │
│ └──────────┘  └────────────────┘   │
│                                    │
│ Expires in: 6 days 23 hours        │
│                                    │
└────────────────────────────────────┘
```

### Wallet Sharing Flow

```
┌────────────────────────────────────┐
│       Share Wallets                │
├────────────────────────────────────┤
│                                    │
│ Select wallets to share with       │
│ your family:                       │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ ☐ 💰 My Cash        $1,500    │ │
│ │ ☑️ 🏠 Household      $2,000    │ │
│ │ ☐ 💳 Credit Card    -$500     │ │
│ │ ☑️ 🎉 Vacation Fund  $5,000    │ │
│ └────────────────────────────────┘ │
│                                    │
│ ⚠️ Sharing allows family members   │
│ to view transactions and           │
│ (editors) add new ones.            │
│                                    │
│ ┌────────────────────────────────┐ │
│ │    Save Changes                │ │
│ └────────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘
```

---

## Invite Link Format

```
join.bexly.app/f/ABC123XY   → Family invite (random 8-char code)
join.bexly.app/f/joyng      → Family invite via username
join.bexly.app/f/u_abc123   → Family invite via user ID (default)
join.bexly.app/joyng        → Referral link (future feature)
```

### Username System

- **Default**: `u_` + 6-char short ID (e.g., `u_7x9k2m`)
- **Custom**: User can claim a unique username later (e.g., `joyng`)
- **One-time**: Username can only be claimed once, cannot be changed
- **Validation**: 3-20 chars, alphanumeric + underscore, must start with letter

---

## Role Permissions

| Permission | Owner | Editor | Viewer |
|------------|-------|--------|--------|
| View shared wallets | ✅ | ✅ | ✅ |
| View shared transactions | ✅ | ✅ | ✅ |
| Add transactions | ✅ | ✅ | ❌ |
| Edit own transactions | ✅ | ✅ | ❌ |
| Edit others' transactions | ✅ | ❌ | ❌ |
| Delete transactions | ✅ | ✅ (own) | ❌ |
| Share/unshare wallets | ✅ | ❌ | ❌ |
| Invite members | ✅ | ❌ | ❌ |
| Remove members | ✅ | ❌ | ❌ |
| Change member roles | ✅ | ❌ | ❌ |
| Delete family | ✅ | ❌ | ❌ |
| Leave family | ❌ | ✅ | ✅ |

---

## Database Schema

### New Drift Tables

#### 1. FamilyGroups
```dart
class FamilyGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get ownerId => text()(); // Firebase UID
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get maxMembers => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### 2. FamilyMembers
```dart
class FamilyMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().unique()();
  TextColumn get familyCloudId => text()(); // FK
  TextColumn get userId => text()(); // Firebase UID
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get email => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('viewer'))(); // owner, editor, viewer
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, active, left
  DateTimeColumn get joinedAt => dateTime().nullable()();
  DateTimeColumn get invitedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### 3. FamilyInvitations
```dart
class FamilyInvitations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().unique()();
  TextColumn get familyCloudId => text()(); // FK
  TextColumn get invitedEmail => text()();
  TextColumn get invitedByUserId => text()();
  TextColumn get inviteCode => text().unique()(); // 8-char for deep link
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, accepted, rejected, expired
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get respondedAt => dateTime().nullable()();
}
```

#### 4. SharedWallets
```dart
class SharedWallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().unique()();
  TextColumn get familyCloudId => text()(); // FK
  TextColumn get walletCloudId => text()(); // FK
  TextColumn get sharedByUserId => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sharedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### 5. UserProfiles (new table for username)
```dart
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cloudId => text().unique()();
  TextColumn get userId => text().unique()(); // Firebase UID
  TextColumn get username => text().unique().nullable()(); // Custom or null
  TextColumn get defaultUsername => text()(); // u_shortid (always set)
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

### Modify Existing Tables

#### Transactions - Add columns:
```dart
TextColumn get createdByUserId => text().nullable()();
TextColumn get createdByDisplayName => text().nullable()();
TextColumn get lastModifiedByUserId => text().nullable()();
```

#### Wallets - Add columns:
```dart
BoolColumn get isShared => boolean().withDefault(const Constant(false))();
TextColumn get ownerUserId => text().nullable()();
```

---

## Firestore Structure

```
firestore/
├── families/{familyCloudId}/
│   ├── name: string
│   ├── ownerId: string (Firebase UID)
│   ├── iconName: string?
│   ├── colorHex: string?
│   ├── maxMembers: number (5)
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   │
│   ├── members/{memberCloudId}/
│   │   ├── userId: string
│   │   ├── displayName: string
│   │   ├── email: string
│   │   ├── avatarUrl: string?
│   │   ├── role: 'owner' | 'editor' | 'viewer'
│   │   ├── status: 'active' | 'pending' | 'left'
│   │   ├── joinedAt: timestamp?
│   │   └── updatedAt: timestamp
│   │
│   ├── invitations/{invitationCloudId}/
│   │   ├── invitedEmail: string
│   │   ├── invitedByUserId: string
│   │   ├── inviteCode: string (8-char)
│   │   ├── role: 'editor' | 'viewer'
│   │   ├── status: 'pending' | 'accepted' | 'rejected' | 'expired'
│   │   ├── expiresAt: timestamp
│   │   └── createdAt: timestamp
│   │
│   ├── shared_wallets/{sharedWalletCloudId}/
│   │   ├── walletCloudId: string
│   │   ├── sharedByUserId: string
│   │   ├── isActive: boolean
│   │   └── sharedAt: timestamp
│   │
│   └── shared_data/
│       ├── wallets/items/{walletCloudId}/
│       │   └── (wallet document with ownerUserId)
│       │
│       └── transactions/items/{transactionCloudId}/
│           ├── (transaction fields)
│           ├── createdByUserId: string
│           ├── createdByDisplayName: string
│           └── lastModifiedByUserId: string
│
├── users/{userId}/
│   ├── profile/
│   │   ├── username: string?
│   │   ├── defaultUsername: string (u_shortid)
│   │   ├── displayName: string?
│   │   └── avatarUrl: string?
│   │
│   ├── familyId: string? (current active family)
│   │
│   └── data/ (existing personal data - unchanged)
│       ├── wallets/items/{cloudId}
│       ├── transactions/items/{cloudId}
│       └── ...
│
└── usernames/{username}/
    └── userId: string (for username uniqueness check)
```

---

## Sync Architecture

### FamilySyncService

Extends existing `RealtimeSyncService` with family-specific listeners:

```dart
class FamilySyncService {
  // Listeners
  StreamSubscription? _familyListener;
  StreamSubscription? _membersListener;
  StreamSubscription? _invitationsListener;
  StreamSubscription? _sharedWalletsListener;
  StreamSubscription? _sharedTransactionsListener;

  // Start listening when user joins/creates family
  Future<void> startFamilySync(String familyCloudId);

  // Stop listening when user leaves family
  Future<void> stopFamilySync();

  // Upload shared transaction
  Future<void> uploadSharedTransaction(TransactionModel tx, String userId);

  // Handle conflicts (Last-Write-Wins with user tracking)
  Future<void> resolveConflict(String cloudId, Map<String, dynamic> remote, Transaction? local);
}
```

### Conflict Resolution

- **Strategy**: Last-Write-Wins based on `updatedAt` timestamp
- **User Tracking**: Always preserve `createdByUserId`, update `lastModifiedByUserId`
- **Notification**: Alert user if someone else modified their transaction

---

## Edge Cases

### Member Leaves Family
1. Mark member status as 'left' in Firestore
2. Remove family reference from user document
3. Keep their transactions in shared space (preserve history)
4. Clear local family data on their device
5. Future transactions go to personal space only

### Owner Deletes Family
1. Only owner can delete
2. Migrate shared wallet data back to original owners
3. Delete all family collections in Firestore
4. Remove family reference from all member documents
5. Notify all members via push notification

### Wallet Unshared
1. Mark `SharedWallet.isActive = false`
2. Keep transaction history in shared space
3. Future transactions go to personal space only
4. Other members can still view historical transactions

### Simultaneous Edits
1. Use Firestore transactions for atomic operations
2. Version field for optimistic locking
3. Last-Write-Wins if versions conflict
4. Show "Updated by X" indicator in UI

---

## Subscription Tier

### Family Tier
- **Price**: ~$5.99-6.99/month (or ~$59/year)
- **Includes**: All Pro features + Family sharing
- **Limits**:
  - Max 5 family members
  - Unlimited shared wallets
  - Unlimited shared transactions

### Who Can Do What
- **Anyone** can JOIN a family (even free users)
- **Only Family tier** can CREATE a family
- **Only Family tier** can INVITE members

---

## Implementation Phases

### Phase 1: Database & Models
- [ ] Create Drift tables (4 new + 1 UserProfiles)
- [ ] Modify existing tables (Transactions, Wallets)
- [ ] Create migration v19
- [ ] Create Freezed models
- [ ] Create DAOs

### Phase 2: Firestore & Sync
- [ ] Setup Firestore collections structure
- [ ] Create FamilySyncService
- [ ] Integrate with existing RealtimeSyncService
- [ ] Implement conflict resolution

### Phase 3: Domain Layer
- [ ] Create FamilyRole enum with permissions
- [ ] Create WorkspaceType enum
- [ ] Create FamilyPermissionService
- [ ] Create FamilyRepository

### Phase 4: Riverpod Providers
- [ ] currentWorkspaceProvider
- [ ] currentFamilyProvider
- [ ] familyMembersProvider
- [ ] pendingInvitationsProvider
- [ ] sharedWalletsProvider

### Phase 5: UI - Core
- [ ] WorkspaceSwitcherTab component
- [ ] Update Dashboard with workspace switcher
- [ ] Family wallet list with contributions
- [ ] Transaction list with author info

### Phase 6: UI - Family Management
- [ ] FamilySettingsScreen
- [ ] FamilyMembersScreen
- [ ] InviteMemberScreen
- [ ] ShareWalletScreen
- [ ] InvitationResponseScreen

### Phase 7: Deep Links & Notifications
- [ ] Setup join.bexly.app routing
- [ ] Handle deep link in app
- [ ] Push notifications for invites
- [ ] Email notifications (optional)

### Phase 8: Subscription Integration
- [ ] Add Family tier to subscription system
- [ ] Gate family creation behind subscription
- [ ] Update subscription UI

---

## File Structure

```
lib/features/family/
├── data/
│   ├── models/
│   │   ├── family_group_model.dart
│   │   ├── family_group_model.freezed.dart
│   │   ├── family_member_model.dart
│   │   ├── family_invitation_model.dart
│   │   ├── shared_wallet_model.dart
│   │   └── user_profile_model.dart
│   └── repositories/
│       ├── family_repository.dart
│       └── user_profile_repository.dart
│
├── domain/
│   ├── enums/
│   │   ├── family_role.dart
│   │   ├── member_status.dart
│   │   ├── invitation_status.dart
│   │   └── workspace_type.dart
│   └── services/
│       ├── family_permission_service.dart
│       └── username_service.dart
│
├── presentation/
│   ├── screens/
│   │   ├── family_settings_screen.dart
│   │   ├── family_members_screen.dart
│   │   ├── invite_member_screen.dart
│   │   ├── share_wallet_screen.dart
│   │   ├── invitation_response_screen.dart
│   │   └── claim_username_screen.dart
│   │
│   ├── components/
│   │   ├── workspace_switcher_tab.dart
│   │   ├── family_member_tile.dart
│   │   ├── invitation_card.dart
│   │   ├── shared_wallet_tile.dart
│   │   ├── family_balance_summary.dart
│   │   ├── member_contribution_chart.dart
│   │   └── transaction_author_badge.dart
│   │
│   └── riverpod/
│       ├── family_providers.dart
│       ├── workspace_provider.dart
│       ├── family_members_provider.dart
│       ├── invitations_provider.dart
│       ├── shared_wallets_provider.dart
│       └── user_profile_provider.dart
│
└── services/
    └── family_sync_service.dart
```

---

## Critical Files to Modify

| Purpose | File Path |
|---------|-----------|
| Database | `lib/core/database/app_database.dart` |
| Transaction table | `lib/core/database/tables/transaction_table.dart` |
| Wallet table | `lib/core/database/tables/wallet_table.dart` |
| Realtime sync | `lib/core/services/sync/realtime_sync_service.dart` |
| Firestore | `lib/core/database/firestore_database.dart` |
| Subscription | `lib/core/services/subscription/subscription_tier.dart` |
| Dashboard | `lib/features/dashboard/presentation/screens/dashboard_screen.dart` |
| Router | `lib/core/router/app_router.dart` |

---

## Estimated Effort

- **New files**: ~30 files
- **Modified files**: ~12 files
- **New Drift tables**: 5
- **New Firestore collections**: 5
- **Database migration**: v18 → v19
- **Estimated time**: 2-3 weeks for full implementation
