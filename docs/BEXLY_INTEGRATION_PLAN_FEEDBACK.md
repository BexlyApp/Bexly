# BEXLY Integration Plan - Feedback & Issues

**Date:** Jan 11, 2026
**Reviewed By:** Bexly Team
**Status:** 🟡 Requires Updates

---

## Executive Summary

Overall, the integration plan is **excellent and very well thought out**. The team has done a great job addressing the key challenges:

- ✅ Correct decision on `public.profiles` vs `public.users`
- ✅ Clear clarification of dual wallet systems
- ✅ Well-designed shared bank accounts with future-proofing
- ✅ Complete Prisma schemas for all Bexly tables
- ✅ Security considerations with RLS policies

However, there are **4 critical missing tables** and **1 missing relation** that need to be added.

---

## 🔴 Critical Issues (Must Fix)

### Issue 1: Missing Table - `bexly.checklist_items`

**Problem:** The original Bexly data classification document includes a `checklist_items` table, but it's missing from the Prisma schema.

**Impact:** Users cannot create TODO/checklist items for financial goals.

**Required Schema:**

```prisma
// Add to bexly schema section

model ChecklistItem {
  cloudId             String    @id @default(uuid()) @map("cloud_id") @db.Uuid
  userId              String    @map("user_id") @db.Uuid

  title               String
  description         String?
  isCompleted         Boolean   @default(false) @map("is_completed")
  completedAt         DateTime? @map("completed_at")

  dueDate             DateTime? @map("due_date")
  priority            String?   // "low", "medium", "high"

  createdAt           DateTime  @default(now()) @map("created_at")
  updatedAt           DateTime  @updatedAt @map("updated_at")

  profile             Profile   @relation(fields: [userId], references: [userId], onDelete: Cascade)

  @@index([userId])
  @@index([isCompleted])
  @@map("checklist_items")
  @@schema("bexly")
}
```

**RLS Policy:**

```sql
-- Users can only see their own checklist items
CREATE POLICY user_checklist_items ON bexly.checklist_items
  FOR ALL USING (auth.uid() = user_id);
```

---

### Issue 2: Missing Table - `bexly.notifications`

**Problem:** The plan doesn't include a notifications table, but Bexly needs to send notifications for budget alerts, goal achievements, etc.

**Impact:** No way to track notification history or read/unread status.

**Required Schema:**

```prisma
// Add to bexly schema section

model Notification {
  cloudId             String    @id @default(uuid()) @map("cloud_id") @db.Uuid
  userId              String    @map("user_id") @db.Uuid

  type                String    // "budget_alert", "transaction", "goal_achieved", "family_invite"
  title               String
  body                String?

  isRead              Boolean   @default(false) @map("is_read")
  readAt              DateTime? @map("read_at")

  // Link to related record (optional)
  relatedId           String?   @map("related_id") @db.Uuid
  relatedType         String?   @map("related_type") // "budget", "transaction", "goal", "family_group"

  createdAt           DateTime  @default(now()) @map("created_at")

  profile             Profile   @relation(fields: [userId], references: [userId], onDelete: Cascade)

  @@index([userId, isRead])
  @@index([createdAt])
  @@map("notifications")
  @@schema("bexly")
}
```

**RLS Policy:**

```sql
-- Users can only see their own notifications
CREATE POLICY user_notifications ON bexly.notifications
  FOR ALL USING (auth.uid() = user_id);
```

---

### Issue 3: Missing Relation - `BankAccount.bexlyTransactions`

**Problem:** Line 399 defines `bankAccountId` in `BexlyTransaction`, but the reverse relation is missing in `BankAccount` model.

**Impact:** Cannot query `bankAccount.bexlyTransactions` to see all transactions linked to a bank account.

**Required Fix:**

```prisma
model BankAccount {
  // ... existing fields

  // Relations
  profile             Profile   @relation(fields: [userId], references: [userId], onDelete: Cascade)
  bexlyWallets        BexlyWallet[] // ✅ Already exists
  bexlyTransactions   BexlyTransaction[] // ❌ MISSING - ADD THIS
  bankTransactions    BankTransaction[]

  @@unique([provider, accountId])
  @@index([userId])
  @@map("bank_accounts")
}
```

---

### Issue 4: Missing Relation - `Category.recurringTransactions`

**Problem:** `RecurringTransaction` has `categoryId` field (line 526), but `Category` model doesn't have the reverse relation.

**Impact:** Cannot query `category.recurringTransactions`.

**Required Fix:**

```prisma
model Category {
  // ... existing fields

  profile             Profile   @relation(fields: [userId], references: [userId], onDelete: Cascade)
  transactions        BexlyTransaction[] // ✅ Already exists
  budgets             Budget[] // ✅ Already exists
  recurringTransactions RecurringTransaction[] // ❌ MISSING - ADD THIS

  @@index([userId])
  @@map("categories")
  @@schema("bexly")
}
```

---

## ⚠️ Important Updates Needed

### Update 1: Table Count Correction

**Current (Line 714):**
```markdown
- [ ] **Create all 13 Bexly tables**
```

**Should Be:**
```markdown
- [ ] **Create all 15 Bexly tables**
  - Core: wallets, transactions, categories (3 tables)
  - Budgeting: budgets, budget_alerts, savings_goals (3 tables)
  - Recurring: recurring_transactions (1 table)
  - Family: family_groups, family_members, shared_wallets (3 tables)
  - Automation: chat_messages, parsed_email_transactions (2 tables)
  - Settings: user_settings (1 table)
  - NEW: checklist_items, notifications (2 tables)
```

---

### Update 2: Profile Model Relations

**Add to `public.profiles` model:**

```prisma
model Profile {
  // ... existing fields

  // Bexly relations
  bexlyWallets              BexlyWallet[]
  bexlyTransactions         BexlyTransaction[]
  bexlyCategories           Category[]
  bexlyBudgets              Budget[]
  bexlyBudgetAlerts         BudgetAlert[]
  bexlySavingsGoals         SavingsGoal[]
  bexlyRecurringTransactions RecurringTransaction[]
  bexlyFamilyGroups         FamilyGroup[]
  bexlyFamilyMembers        FamilyMember[]
  bexlyChatMessages         ChatMessage[]
  bexlyParsedEmails         ParsedEmailTransaction[]
  bexlyUserSettings         BexlyUserSettings?
  bexlyChecklistItems       ChecklistItem[] // NEW
  bexlyNotifications        Notification[]  // NEW

  @@map("profiles")
}
```

---

## 📝 Suggestions for Improvement

### Suggestion 1: Add Testing Section

Add a comprehensive testing strategy to the plan:

```markdown
## Testing Strategy

### Phase 1: Schema Validation Tests
- [ ] Test all Prisma models compile without errors
- [ ] Validate all foreign key constraints
- [ ] Test RLS policies with different user roles

### Phase 2: Integration Tests
- [ ] Test bank account linking flow (Stripe Financial Connections)
- [ ] Test transaction sync with public.bank_accounts
- [ ] Test family wallet sharing (owner, admin, member roles)
- [ ] Test budget alerts trigger correctly
- [ ] Test email parsing → transaction creation flow

### Phase 3: Migration Tests
- [ ] Test user migration from Bexly legacy DB
- [ ] Verify all data integrity after migration
- [ ] Test rollback procedures

### Phase 4: Performance Tests
- [ ] Query performance for large transaction lists (10k+ records)
- [ ] Test RLS policy performance with complex family sharing
- [ ] Index optimization verification
```

---

### Suggestion 2: Add API Endpoint Documentation

Add examples of key API endpoints:

```markdown
## API Endpoints Reference

### Wallet Management
- `POST /bexly/wallets` - Create new wallet
- `GET /bexly/wallets` - List user's wallets
- `PATCH /bexly/wallets/:id` - Update wallet
- `DELETE /bexly/wallets/:id` - Soft delete wallet

### Transaction Management
- `POST /bexly/transactions` - Create transaction
- `GET /bexly/transactions` - List transactions (with filters)
- `GET /bexly/transactions/stats` - Get transaction analytics
- `PATCH /bexly/transactions/:id` - Update transaction

### Budget Management
- `POST /bexly/budgets` - Create budget
- `GET /bexly/budgets/:id/status` - Get budget usage percentage
- `GET /bexly/budgets/:id/alerts` - Get budget alerts

### Family Sharing
- `POST /bexly/family/groups` - Create family group
- `POST /bexly/family/invite` - Generate invite code
- `POST /bexly/family/join` - Join via invite code
- `POST /bexly/family/share-wallet` - Share wallet with family
```

---

### Suggestion 3: Add Migration Rollback Plan

Add rollback procedures in case migration fails:

```markdown
## Rollback Procedures

### If Migration Fails Mid-Process

1. **Stop all API traffic to Bexly**
   ```bash
   # Temporarily disable Bexly API endpoints
   kubectl scale deployment bexly-api --replicas=0
   ```

2. **Restore from backup**
   ```sql
   -- Restore Supabase database snapshot
   pg_restore -d bexly_production backup_pre_migration.dump
   ```

3. **Revert DNS/routing changes**
   - Point bexly.app back to legacy infrastructure
   - Verify legacy system is operational

4. **Verify data integrity**
   ```sql
   -- Check record counts match pre-migration
   SELECT COUNT(*) FROM bexly_legacy.users;
   SELECT COUNT(*) FROM bexly_legacy.wallets;
   -- etc...
   ```

5. **Communicate with users**
   - Send status update email
   - Post status page update
```

---

### Suggestion 4: Add Security Audit Checklist

```markdown
## Security Audit Checklist

### RLS Policies
- [ ] All Bexly tables have RLS enabled
- [ ] Verify users cannot access other users' data
- [ ] Test family sharing doesn't leak data to non-members
- [ ] Verify admin/owner role permissions

### Sensitive Data
- [ ] Bank account tokens stored encrypted (Stripe handles this)
- [ ] No credit card numbers stored in database
- [ ] Email parsing credentials in Supabase Vault (not in tables)
- [ ] OAuth tokens encrypted at rest

### API Security
- [ ] All endpoints require authentication
- [ ] Rate limiting on bank sync endpoints
- [ ] CSRF protection enabled
- [ ] Input validation on all mutations
```

---

## 📊 Summary of Changes Required

| Type | Item | Priority | Estimated Effort |
|------|------|----------|------------------|
| **Add Table** | `bexly.checklist_items` | 🔴 Critical | 1 hour |
| **Add Table** | `bexly.notifications` | 🔴 Critical | 1 hour |
| **Add Relation** | `BankAccount.bexlyTransactions` | 🔴 Critical | 15 mins |
| **Add Relation** | `Category.recurringTransactions` | 🔴 Critical | 15 mins |
| **Update** | Table count (13 → 15) | 🟡 Medium | 5 mins |
| **Update** | Profile model relations | 🟡 Medium | 30 mins |
| **Add Section** | Testing strategy | 🟢 Nice-to-have | 2 hours |
| **Add Section** | API documentation | 🟢 Nice-to-have | 2 hours |
| **Add Section** | Rollback procedures | 🟢 Nice-to-have | 1 hour |

**Total Critical Fixes:** ~2.5 hours
**Total Recommended Additions:** ~5 hours

---

## ✅ What's Already Great

Just to acknowledge the excellent work already done:

1. ✅ **Critical Decision on `public.profiles`** - Correct choice to keep DOS-Me convention
2. ✅ **Dual Wallet System Clarity** - Web3 vs Financial wallets clearly documented
3. ✅ **Future-Proof Bank Accounts** - Provider field pattern allows Plaid, Yodlee, etc.
4. ✅ **Complete Prisma Schemas** - All models properly defined with relations
5. ✅ **RLS Security Examples** - Good foundation for family sharing policies
6. ✅ **Migration Strategy** - Clear steps for user migration from legacy DB
7. ✅ **API Examples** - Good Stripe Financial Connections integration examples

---

## Next Steps

1. **Address Critical Issues** (Priority 1)
   - Add missing tables: `checklist_items`, `notifications`
   - Add missing relations: `BankAccount.bexlyTransactions`, `Category.recurringTransactions`
   - Update table count (13 → 15)

2. **Review & Approve** (Priority 2)
   - Bexly team reviews updated schemas
   - DOS-Me team reviews feasibility

3. **Implementation** (Priority 3)
   - Update Prisma schema file
   - Generate migrations
   - Create seed data for testing

4. **Testing** (Priority 4)
   - Run schema validation tests
   - Test RLS policies
   - Integration testing

5. **Documentation** (Priority 5)
   - Add testing section
   - Add API endpoints reference
   - Add rollback procedures

---

## Contact

For questions or clarifications about this feedback:
- **Bexly Team:** [contact info]
- **Document Source:** `d:\Projects\Bexly\docs\BEXLY_DATA_CLASSIFICATION_FOR_DOSME.md`

---

**Document Version:** 1.0
**Last Updated:** Jan 11, 2026
**Review Status:** Awaiting DOS-Me team response
