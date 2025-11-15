# AI Chat Transaction Debug Log

## Ngày: 2025-11-07
## Developer: Claude Code

---

## SESSION: WALLET DUPLICATION BUG FIX (v194)

### Vấn đề
**Critical Bug:** Khi edit wallet và bấm Save → tạo ra wallet duplicate với tên mới (ví dụ: "My Wallet 2" → "My Wallet 3")

### Root Cause Analysis
**Race condition trong `uploadWallet`:**

1. User edit wallet "My Wallet 2" (id=1, cloudId=NULL trong memory)
2. `updateWallet` gọi `uploadWallet(wallet)` với `wallet.cloudId = null`
3. `uploadWallet` **TẠO cloudId MỚI ngay lập tức** (line 949: `final cloudId = wallet.cloudId ?? const Uuid().v7()`)
4. Upload lên Firestore với cloudId mới
5. **Realtime listener nhận event "modified" với cloudId mới**
6. Listener check `getWalletByCloudId(newCloudId)` → NULL (vì local database chưa có cloudId này!)
7. → Gọi `_insertWalletFromCloud` → **TẠO WALLET MỚI**
8. Sau đó `uploadWallet` mới cập nhật cloudId vào database (quá muộn!)

**Timeline thực tế:**
```
T1: uploadWallet generates new cloudId
T2: Firestore upload completes
T3: Listener receives event → can't find wallet → creates duplicate
T4: uploadWallet updates local database with cloudId (TOO LATE!)
```

### Fix Implementation
**File:** `lib/core/services/sync/realtime_sync_service.dart`

**Thay đổi trong `uploadWallet` (lines 948-973):**

**Trước:**
```dart
// Generate cloudId if not exists
final cloudId = wallet.cloudId ?? const Uuid().v7();
```

**Sau:**
```dart
// CRITICAL FIX: Read cloudId from database FIRST before generating new one
String cloudId;
if (wallet.cloudId != null) {
  cloudId = wallet.cloudId!;
} else if (wallet.id != null) {
  // Read from database first to avoid generating duplicate cloudId
  final currentWallet = await (_db.select(_db.wallets)
    ..where((w) => w.id.equals(wallet.id!)))
    .getSingleOrNull();

  if (currentWallet?.cloudId != null) {
    // Use existing cloudId from database
    cloudId = currentWallet!.cloudId!;
  } else {
    // Generate new cloudId only if truly doesn't exist
    cloudId = const Uuid().v7();
  }
} else {
  cloudId = const Uuid().v7();
}
```

**Kết quả:**
- Khi edit wallet, luôn dùng cloudId cũ từ database
- Listener nhận event với cloudId cũ → tìm thấy wallet → chỉ UPDATE, không tạo mới
- ✅ No more duplicates!

### Related Fixes
**File:** `lib/features/dashboard/presentation/components/wallet_amount_edit_button.dart`
- Fixed edit button to use `dashboardWalletFilterProvider` instead of `activeWalletProvider`
- Hide edit button when in "Total Balance" mode

**File:** `lib/features/settings/presentation/components/profile_card.dart`
- Fixed profile card refresh after updating personal details

### Testing
- [x] Edit wallet multiple times - no duplicates created
- [x] Edit button visibility correct in Total vs single wallet mode
- [x] Cloud sync works correctly with existing wallets
- [x] Login pulls wallets without duplication

### Version
**v194** - Released 2025-11-07

### Commits
- `b21d7e4` - fix(sync): Fix wallet duplication bug when editing wallets (v194)

---

## PREVIOUS SESSION: AI CHAT TRANSACTION DEBUG

## Ngày: 2025-09-27
## Developer: Claude Code

---

## 1. VẤN ĐỀ CHÍNH

**Mô tả:** AI chat hiển thị thông báo thành công khi tạo transaction nhưng transaction không được lưu vào database.

**Triệu chứng:**
- User nhập "Ăn tối 200k" → AI trả lời "Đã ghi nhận chi 200.000 USD cho Ăn tối"
- Không có transaction nào xuất hiện trong tab Transactions
- Tạo transaction thủ công vẫn hoạt động bình thường

---

## 2. CÁC BƯỚC ĐÃ THỰC HIỆN

### 2.1. Cấu hình OpenAI API ✅
- Đã setup flutter_dotenv để load API key từ .env file
- Sử dụng model gpt-4o-mini (không phải GPT-5 như ban đầu nhầm lẫn)
- API key và model được load từ environment variables

### 2.2. Cải thiện System Prompt ✅
- Đã update prompt cho OpenAI service để luôn trả về ACTION_JSON
- Set temperature = 0 để đảm bảo output deterministic
- Thêm ví dụ cụ thể về format ACTION_JSON

### 2.3. Thêm Debug Logging Chi Tiết ✅
- Đã thêm extensive logging trong `_createTransactionFromAction`
- Log toàn bộ flow từ nhận action → parse data → insert database
- Sử dụng label TRANSACTION_DEBUG và TRANSACTION_ERROR để dễ filter

### 2.4. Kiểm Tra Database Layer ✅
- TransactionDao.addTransaction() có vẻ đúng implementation
- Sử dụng TransactionsCompanion để insert
- Log được thêm ở đầu hàm addTransaction

---

## 3. PHÁT HIỆN QUAN TRỌNG

### 3.1. Vấn Đề Currency
- AI response hiển thị "200.000 USD" thay vì VND hoặc currency của wallet
- Có thể wallet đang dùng USD làm currency mặc định

### 3.2. Flow Hiện Tại
```
User input → AI Service → Parse ACTION_JSON → _createTransactionFromAction → TransactionDao.addTransaction
```

### 3.3. Các Điểm Cần Debug Thêm
1. **Wallet state:** Kiểm tra xem wallet có đúng ID và currency không
2. **Category matching:** Category có được match đúng không
3. **Database insert:** Insert có thực sự thành công không
4. **UI refresh:** Sau khi insert, UI có được refresh không

---

## 4. NGHI VẤN CHÍNH

### Giả thuyết 1: Transaction được tạo nhưng không hiển thị
- Do filter sai wallet ID
- Do query transactions không include transaction mới

### Giả thuyết 2: Transaction không được tạo
- Database insert fail silently
- Wallet ID hoặc Category ID null/invalid
- Transaction model không valid

### Giả thuyết 3: UI không refresh
- Provider không trigger rebuild
- Stream không emit new data

---

## 5. BƯỚC TIẾP THEO CẦN LÀM

### Immediate Actions:
1. **Test với debug logs mới:**
   - Hot reload app với code mới
   - Test lại "Ăn tối 200k"
   - Xem console output với filter TRANSACTION_DEBUG

2. **Kiểm tra Wallet Currency:**
   - Verify wallet đang active có currency gì
   - Sửa display message để show đúng currency

3. **Verify Database Insert:**
   - Check xem insertedId có return đúng không
   - Query lại database sau insert để confirm

### Next Phase:
1. **Fix currency display issue**
2. **Add transaction refresh mechanism**
3. **Test với nhiều test cases khác nhau**

---

## 6. CODE CHANGES SUMMARY

### Files Modified:
1. **chat_provider.dart:**
   - Added extensive debug logging
   - Enhanced error handling with stack trace
   - Added step-by-step logging in transaction creation

2. **ai_service.dart:**
   - Improved system prompt for Vietnamese financial assistant
   - Set temperature to 0 for consistent output
   - Added clear ACTION_JSON examples

3. **.env & llm_config.dart:**
   - Configured to use environment variables
   - Using gpt-4o-mini model

---

## 7. TESTING CHECKLIST

- [ ] Hot reload với debug logs mới
- [ ] Test "Ăn tối 200k" và xem TRANSACTION_DEBUG logs
- [ ] Test "Mua nhà 2 tỷ" với số lớn
- [ ] Test income transaction "Lương 30tr"
- [ ] Verify transaction xuất hiện trong UI
- [ ] Check wallet balance có update không

---

## 8. NOTES CHO DEVELOPER TIẾP THEO

- User rất frustrated với bug này, cần fix ASAP
- KHÔNG dùng full path cho flutter commands (chỉ dùng `flutter`)
- App đang chạy trên emulator-5554
- Console logs có thể xem qua flutter run output
- User test bằng tiếng Việt với các amount shortcuts (k, tr, tỷ)

---

## STATUS: 🔴 CHƯA GIẢI QUYẾT

**Cần làm ngay khi user online:**
1. Kiểm tra debug logs từ test mới
2. Fix dựa trên log output
3. Test lại và confirm fix hoạt động

---

## 9. UPDATE: 2025-09-28

### 9.1. Fix UI Issue - Balance Bar
**Vấn đề:** Thanh balance "My Wallet" hiển thị ở Settings screen không cần thiết

**Giải pháp:**
- Thêm `showBalance: false` vào CustomScaffold trong SettingsScreen
- File: `lib/features/settings/presentation/screens/settings_screen.dart` (line 52)

**Kết quả:** ✅ Settings screen không còn hiển thị balance bar

### 9.2. Transaction Bug Status
- Vẫn cần test với debug logs để tìm nguyên nhân transaction không lưu
- Cần kiểm tra flow: AI response → Parse → Database insert → UI refresh

---

## 10. UPDATE: 2025-11-03 - Category Matching Architecture

### 10.1. Problem: LLM Choosing Wrong Category Level
**Issue:** Netflix being assigned to "Entertainment" (parent) instead of "Streaming" (subcategory)

**Root Cause Analysis:**
1. Prompt example shows: `"category":"Entertainment"` (line 144 in ai_prompts.dart)
2. LLM learns from examples → copies parent category instead of subcategory
3. Code validation was trying to "fix" LLM's choice with fuzzy matching

### 10.2. Research: Best Practices (2025)

**Industry Standards for LLM Classification:**

1. **Constrained Generation (Preferred but complex):**
   - Guarantees output compliance at generation time
   - No need for validation/retry loops
   - Requires library support (Outlines, vLLM)
   - More efficient (no wasted tokens)

2. **Post-Processing with Validation (Traditional):**
   - Flexible, works with any LLM
   - Requires retry loops when validation fails
   - Can handle complex validation logic

3. **Hybrid "Trust but Verify" (Production Standard):**
   - ✅ Use prompt engineering to guide LLM (80% solution)
   - ✅ Add lightweight validation as safety net (20%)
   - ✅ Log validation failures for prompt improvement
   - ✅ Don't use "smart" code to fix LLM output - just validate

**References:**
- Constrained generation eliminates need for post-validation (Zilliz, 2025)
- Structured outputs with JSON schema provide 100% compliance (vLLM 0.8.5+)
- Few-shot examples are critical for classification accuracy (Prompt Engineering Guide)

### 10.3. Implemented Solution: Hybrid Approach

**Phase 1: Fix Prompt (Root Cause)** 🎯
```dart
// OLD (line 144):
JSON: {"action":"create_recurring","name":"Netflix",...,"category":"Entertainment",...}

// NEW:
JSON: {"action":"create_recurring","name":"Netflix",...,"category":"Streaming",...}
```

**Added explicit guidance:**
- Counter-example: ❌ Netflix → "Entertainment", ✅ Netflix → "Streaming"
- Reinforced: "ALWAYS prefer subcategory (→ marked) over parent (📁 marked)"

**Phase 2: Simplify Validation (Safety Net)**
- Keep exact match validation (case-insensitive)
- **Removed fuzzy matching** (contains logic) - caused confusion
- If LLM sends invalid category → throw error with clear message
- **Trust LLM's choice** - validate it exists, don't "fix" it

**Phase 3: Monitoring**
- Log when validation fails (indicates prompt needs improvement)
- Track category selection accuracy over time
- Iterative prompt improvement based on real usage

### 10.4. Code Changes (v164)

**File: `lib/features/ai_chat/data/config/ai_prompts.dart`**
- Line 144: Changed Netflix example from "Entertainment" → "Streaming"
- Added counter-example section for category selection
- Enhanced category matching rules with subcategory priority

**File: `lib/features/ai_chat/presentation/riverpod/chat_provider.dart`**
- Simplified category matching: exact match only (case-insensitive)
- Removed fuzzy matching (contains logic)
- Added clear error messages when category not found
- Trust LLM output, just validate existence

**Philosophy:**
- **Prompt engineering > Code fixes**
- **Simple validation > Complex matching**
- **Fail loudly > Silent fixes**
- **Learn from failures > Hide them**

### 10.5. Testing Checklist (v164)

- [ ] Netflix subscription → should assign to "Streaming"
- [ ] Spotify subscription → should assign to "Music"
- [ ] Food transactions → should assign to specific subcategory (e.g., "Breakfast")
- [ ] Invalid category from LLM → should throw clear error
- [ ] Monitor logs for validation failures

**Expected Outcome:** LLM learns correct category selection from improved examples, validation catches edge cases without "fixing" LLM's intent.
---

## SESSION: MULTI-LANGUAGE CATEGORY MAPPING & BUILT-IN PROTECTION (v257)

### Ngày: 2025-11-13
### Developer: Claude Code

---

### 11.1. Problem: Language-Specific Transaction Creation Failure

**Issue:** Chinese/Vietnamese input fails to create transactions while English works fine.

**Test Case:**
- ❌ Chinese: "Spotify 每月 5500元" → No transaction created
- ✅ English: "YouTube Premium subscription $20 monthly" → Transaction created successfully

**Root Cause Discovery:**
1. User chats in Chinese → Gemini AI returns `"category":"Music"` (English)
2. User's database has categories in Chinese: "音乐" (Music)
3. Exact match fails: "Music" ≠ "音乐"
4. Exception thrown → Transaction not created
5. Exception caught silently → User sees success message but no transaction

**Evidence from logs:**
```
11-13 15:43:53.763 I flutter : Exception caught: Category "Music" not found
11-13 15:43:53.763 I flutter : Stack trace: #0 ChatNotifier._createRecurringFromAction
```

### 11.2. Solution: Multi-Language Category Mapping

**Architecture Decision:**
- AI **ALWAYS** returns English category names in `ACTION_JSON`
- Code maps English names → Localized names in database
- User sees localized names in UI, but backend uses English for consistency

**Implementation:**

**1. AI Prompt Enhancement** (`ai_prompts.dart:102-113, 232-246`)
```dart
static const String categoryMatchingRules = '''
CATEGORY MATCHING:
3. CRITICAL: Return category name in ENGLISH in your ACTION_JSON
   - Even if user chats in Chinese/Vietnamese/other languages
   - Even if categories in list are localized (Chinese: "音乐", Vietnamese: "Âm nhạc")
   - You must map to English equivalent (e.g., "Music", "Food", "Transportation")
''';
```

**2. Category Translation Map** (NEW FILE: `category_translation_map.dart`)
```dart
class CategoryTranslationMap {
  static const Map<String, List<String>> mapping = {
    'Music': ['Music', 'Streaming', 'Âm nhạc', 'Nhạc', '音乐'],
    'Food': ['Food & Drinks', 'Ăn uống', '食品', '食物', '餐饮'],
    'Transportation': ['Transportation', 'Di chuyển', '交通'],
    // ... 40+ categories with translations
  };
}
```

**3. Smart Category Matching** (`chat_provider.dart:1814-1858`)

4-step matching process:
1. **Exact match** (case-insensitive)
2. **Translation mapping**: English → Localized name
3. **Fallback**: Try "General", "Other", etc.
4. **Error**: Throw clear exception if no match

### 11.3. Problem: Built-in Category Corruption via Cloud Sync

**Issue:** Categories like "Music", "Food" were being renamed to "Unknown Category" and losing subcategories.

**Root Cause:**
1. User renames "Music" → "音乐" on Device A
2. Device A syncs to cloud → Cloud has "音乐"
3. Device B downloads from cloud → Built-in category "Music" gets overwritten
4. **Category structure breaks**: `parentId` changes, subcategories lost

### 11.4. Solution: Built-in Category Protection

**Implementation** (`realtime_sync_service.dart:409-437`)

**Block ALL updates except cloudId:**
```dart
// CRITICAL: Protect system default categories from cloud modifications
if (existingCategory.isSystemDefault) {
  Log.w('Ignoring cloud update for system default category');
  // Only update cloudId if missing
  return;
}
```

**Protection Levels:**
1. ✅ Delete protection (already existed)
2. ✅ Modify protection (NEW)
3. ✅ CloudId updates only (NEW)

### 11.5. Bonus Fix: Chat Message Deduplication (v250-v251)

**Database-level deduplication** (`chat_message_dao.dart:40-69`)
**Memory-level deduplication** (`chat_provider.dart:292-335`)

### 11.6. Testing Results (v257)

✅ Multi-language category mapping works
✅ Built-in category protection prevents corruption
✅ Chat deduplication eliminates duplicates

### 11.7. Code Changes Summary

**Files Modified:**
1. `lib/core/utils/category_translation_map.dart` - NEW FILE
2. `lib/core/database/daos/chat_message_dao.dart`
3. `lib/core/services/sync/realtime_sync_service.dart`
4. `lib/features/ai_chat/data/config/ai_prompts.dart`
5. `lib/features/ai_chat/presentation/riverpod/chat_provider.dart`
6. `pubspec.yaml` - v1.0.0+257

### 11.8. Lessons Learned

1. **Language-Specific Bugs are Tricky** - Need to test with multiple languages
2. **Cloud Sync Needs Protection** - Built-in data should be read-only from cloud
3. **Deduplication Needs Multiple Layers** - Database + Memory
4. **Debug Logging is Essential** - Without logs, would never find root cause

### 11.9. Commit

**Commit:** `ef8ebcf` - feat(ai-chat): Implement multi-language category mapping and built-in category protection

**STATUS: ✅ RESOLVED**
