# AI Chat Transaction Debug Log

## Ngày: 2025-11-24
## Developer: Claude Code

---

## BUILD 317: ANALYTICS CHARTS WITH CURRENCY CONVERSION FIX

### Vấn đề
**Chart Bug:** 6-month Income vs Expense chart hiển thị giá trị sai và expense line bị invisible.

**Triệu chứng:**
1. Chart Y-axis hiển thị 36.6M thay vì $4.6K
2. Expense line ($22.60) không visible trên chart vì quá nhỏ so với income ($4.66K)
3. Chart chỉ hiển thị income line, không có expense line

### Root Cause Analysis

**Issue 1: Currency Conversion Missing**
- `FinancialHealthRepository` aggregate raw transaction amounts WITHOUT converting to base currency
- VNĐ amounts (~30M VNĐ) displayed directly instead of converting to USD
- Summary cards had currency conversion (correct $4.66K) but charts didn't

**Evidence from logs:**
```
Month 11/2025: 12 transactions
  💰 Income: Salary = 380.0 (VND)  // Raw VND amount!
  💸 Expense: Spotify = 5.0 (USD)
✅ Month 11/2025: income=4659.0, expense=22.60038
```

**Issue 2: Y-axis Scaling**
- When expense ($22.60) is very small compared to income ($4659), it becomes invisible
- Y-axis scales 0-5.6K based on max income
- Expense at $22.60 is only ~0.4% of scale height

### Solution Implementation

**Part 1: Currency Conversion in Repository (v317)**

**File:** `lib/features/reports/data/repositories/financial_health_repository.dart`

Added ExchangeRateService dependency:
```dart
class FinancialHealthRepository {
  final List<TransactionModel> _transactions;
  final ExchangeRateService _exchangeRateService;  // NEW
  final String _baseCurrency;  // NEW

  FinancialHealthRepository(
    this._transactions,
    this._exchangeRateService,
    this._baseCurrency,
  );
```

Added currency conversion in both aggregation methods:
```dart
// In getLastMonthsSummary() and getCurrentMonthWeeklySummary()
for (var t in transactionsInMonth) {
  double amount = t.amount;

  // Convert to base currency if needed
  if (t.wallet.currency != _baseCurrency) {
    try {
      amount = await _exchangeRateService.convertAmount(
        amount: t.amount,
        fromCurrency: t.wallet.currency,
        toCurrency: _baseCurrency,
      );
    } catch (e) {
      Log.e('Failed to convert ${t.wallet.currency} to $_baseCurrency: $e');
    }
  }

  if (t.transactionType == TransactionType.income) {
    income += amount;  // Now converted!
  }
}
```

**Part 2: Provider Dependency Injection (v317)**

**File:** `lib/features/reports/presentation/riverpod/financial_health_provider.dart`

Updated repository provider to inject dependencies:
```dart
final financialHealthRepositoryProvider =
    Provider<FinancialHealthRepository>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);  // NEW
  final baseCurrency = ref.watch(baseCurrencyProvider);  // NEW

  return FinancialHealthRepository(
    transactionsAsync.whenData((data) => data).value ?? [],
    exchangeRateService,  // Inject service
    baseCurrency,  // Inject base currency
  );
});
```

**Part 3: Intelligent minY Calculation (v317)**

**File:** `lib/features/reports/presentation/components/six_months_income_vs_expense_chart.dart`

Added smart Y-axis scaling to make small expense lines visible:
```dart
// Calculate max Y to give some headroom
double maxIncome = 0;
double maxExpense = 0;
for (var item in data) {
  if (item.income > maxIncome) maxIncome = item.income;
  if (item.expense > maxExpense) maxExpense = item.expense;
}

double maxY = maxIncome > maxExpense ? maxIncome : maxExpense;
maxY = maxY * 1.2;  // 20% buffer

// Calculate minY to ensure small values are visible
double minY = 0;
if (maxExpense > 0 && maxExpense < maxY * 0.05) {
  // If expense < 5% of max, adjust minY to "lift" the line
  minY = -(maxY * 0.1);
}

// Apply to chart
LineChartData(
  minY: minY,
  maxY: maxY,
  // ...
)
```

### Test Results (v317)

**Before Fix:**
- Chart showed 36.6M (raw VNĐ amounts)
- Expense line invisible

**After Fix:**
- Chart shows correct $4.66K income, $22.60 expense
- Both lines visible and properly scaled
- User added more expenses → chart displays correctly

**User Confirmation:** "Tôi thêm expense thì nó lên rồi" ✅

### Code Changes Summary

**Files Modified:**
1. `lib/features/reports/data/repositories/financial_health_repository.dart` - Currency conversion in aggregation
2. `lib/features/reports/presentation/riverpod/financial_health_provider.dart` - Dependency injection
3. `lib/features/reports/presentation/components/six_months_income_vs_expense_chart.dart` - Smart minY calculation
4. `lib/features/reports/presentation/components/weekly_income_vs_expense_chart.dart` - Consistent formatting
5. `pubspec.yaml` - v0.0.7+317

### Lessons Learned

1. **Currency Conversion Must Be Consistent** - If summary cards convert currency, charts must too
2. **Repository Should Handle Business Logic** - Currency conversion belongs in data layer, not UI
3. **Y-axis Scaling Requires Edge Case Handling** - Small values need special treatment
4. **Debug Logs Are Essential** - Without logs showing raw VNĐ amounts, would never find root cause
5. **Test with Real Multi-Currency Data** - Edge cases appear when income/expense ratios are extreme

### Commit

**Commit:** `497ee6e` - fix: resolve currency conversion and chart visualization issues

**STATUS: ✅ RESOLVED**

---

## Ngày: 2025-11-20
## Developer: Claude Code

---

## BUILD 314: SIM CARD CURRENCY DETECTION

### Vấn đề
**UX Issue:** App tự động chọn currency dựa trên locale (ngôn ngữ hệ thống), không chính xác cho người dùng ở các quốc gia khác.
- User ở Việt Nam nhưng dùng ngôn ngữ tiếng Anh (`en-US`) → App chọn USD thay vì VND
- Locale chỉ phản ánh ngôn ngữ, không phản ánh vị trí thực tế của user

### Giải pháp
Implement **3-level location detection** với priority:
1. **SIM card country** (most reliable - actual location)
2. **Timezone mapping** (fallback - offline detection)
3. **Locale country** (last resort - language setting)
4. **Default USD** (if all fail)

### Implementation

#### 1. Android Permission ([AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml#L6))
```xml
<!-- Read phone state for SIM card country detection (no runtime permission needed for basic info) -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" android:maxSdkVersion="32"/>
```
- No user permission popup required for API ≤ 32
- Only reads basic SIM country code, not sensitive data

#### 2. Native Android Implementation ([MainActivity.kt](../android/app/src/main/kotlin/com/joy/bexly/MainActivity.kt))
```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.joy.bexly/device_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimCountryCode" -> {
                        val countryCode = getSimCountryCode()
                        result.success(countryCode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getSimCountryCode(): String? {
        return try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            // Try SIM country
            val simCountry = telephonyManager.simCountryIso
            if (!simCountry.isNullOrEmpty()) {
                return simCountry.uppercase()
            }

            // Fallback: Network country
            val networkCountry = telephonyManager.networkCountryIso
            if (!networkCountry.isNullOrEmpty()) {
                return networkCountry.uppercase()
            }

            null
        } catch (e: Exception) {
            null
        }
    }
}
```

#### 3. Device Location Service ([device_location_service.dart](../lib/core/services/device_location_service.dart))
```dart
class DeviceLocationService {
  static const platform = MethodChannel('com.joy.bexly/device_location');

  static Future<String> getCountryCode() async {
    // Try 1: Get from SIM card (most accurate)
    try {
      final simCountry = await platform.invokeMethod<String>('getSimCountryCode');
      if (simCountry != null && simCountry.isNotEmpty) {
        Log.d('Country from SIM: $simCountry', label: 'location');
        return simCountry.toUpperCase();
      }
    } catch (e) {
      Log.w('Failed to get SIM country: $e', label: 'location');
    }

    // Try 2: Get from timezone
    try {
      final countryCode = _getCountryFromTimezone();
      if (countryCode != null) {
        Log.d('Country from timezone: $countryCode', label: 'location');
        return countryCode;
      }
    } catch (e) {
      Log.w('Failed to get timezone country: $e', label: 'location');
    }

    // Try 3: Get from locale
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode?.toUpperCase();
      if (countryCode != null && countryCode.isNotEmpty) {
        Log.d('Country from locale: $countryCode', label: 'location');
        return countryCode;
      }
    } catch (e) {
      Log.w('Failed to get locale country: $e', label: 'location');
    }

    // Default: US
    Log.d('Using default country: US', label: 'location');
    return 'US';
  }

  static String? _getCountryFromTimezone() {
    final timeZoneName = DateTime.now().timeZoneName;

    const timezoneToCountry = {
      // IANA timezone IDs
      'Asia/Ho_Chi_Minh': 'VN',
      'Asia/Saigon': 'VN',
      'Asia/Bangkok': 'TH',
      'Asia/Jakarta': 'ID',
      'Asia/Singapore': 'SG',
      // ... 15+ countries

      // Timezone abbreviations
      'ICT': 'VN',  // Indochina Time
      'SGT': 'SG',  // Singapore Time
      'JST': 'JP',  // Japan Standard Time
      // ...
    };

    return timezoneToCountry[timeZoneName];
  }
}
```

#### 4. Onboarding Integration ([onboarding_slide_3.dart](../lib/features/onboarding/presentation/components/onboarding_slide_3.dart#L31-L50))
```dart
/// Get currency based on device location using DeviceLocationService
/// Priority: SIM card → Timezone → Locale → Default USD
Future<Currency> _getCurrencyFromDevice(WidgetRef ref) async {
  final currencies = ref.watch(currenciesStaticProvider);

  // Get country code from device (SIM → Timezone → Locale)
  final countryCode = await DeviceLocationService.getCountryCode();

  // Find currency by country code
  final currency = currencies.cast<Currency?>().firstWhere(
    (c) => c?.countryCode == countryCode,
    orElse: () => null,
  );

  // Final fallback to USD
  return currency ?? currencies.firstWhere(
    (c) => c.isoCode == 'USD',
    orElse: () => currencies.first,
  );
}

// In useEffect
useEffect(() {
  if (!isInitialized.value) {
    // Async call to get currency from device
    _getCurrencyFromDevice(ref).then((deviceCurrency) {
      ref.read(currencyProvider.notifier).state = deviceCurrency;
      isInitialized.value = true;
    });
  }
  return null;
}, []);
```

### Test Results

**Emulator (default SIM = US):**
- SIM detection: `us` ✅
- Result: USD currency (correct)

**Emulator (custom SIM = VN):**
- Command: `emulator -avd <name> -prop gsm.sim.operator.iso-country=vn`
- Expected: VND currency 🇻🇳

**Real device with Vietnamese SIM:**
- Viettel/Mobifone/Vinaphone → Auto-detect VND
- No SIM → Fallback to timezone (`Asia/Ho_Chi_Minh` → VN → VND)
- Timezone not mapped → Fallback to locale
- All fail → Default USD

### Benefits
1. **Accurate location detection** - SIM card reflects actual location, not language preference
2. **Offline-first** - Timezone fallback works without internet
3. **No permission popup** - READ_PHONE_STATE doesn't require runtime permission for basic info
4. **Graceful degradation** - 3-level fallback ensures always get a currency
5. **Better UX** - Vietnamese users automatically get VND, not USD

### Files Changed
- `android/app/src/main/AndroidManifest.xml` - Added READ_PHONE_STATE permission
- `android/app/src/main/kotlin/com/joy/bexly/MainActivity.kt` - Platform channel implementation
- `lib/core/services/device_location_service.dart` - NEW: Device location service
- `lib/features/onboarding/presentation/components/onboarding_slide_3.dart` - Integrated SIM detection

---

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

---

## SESSION: VIETNAMESE WALLET TYPE DETECTION (v286-288)

### Ngày: 2025-11-17
### Developer: Claude Code

---

### 12.1. Problem: AI Cannot Match Vietnamese Wallet Type Input

**Issue:** User says "trả bằng thẻ tín dụng" (pay with credit card) but AI cannot find the wallet and transaction goes to wrong wallet.

**Test Cases:**
- ❌ Initial: "Ăn sáng $10 trả bằng thẻ tín dụng" → AI says "Đã ghi nhận... vào ví Credit Card" BUT transaction created in "USD (USD)" cash wallet
- ❌ After partial fix: "Ăn sáng $10 trả bằng thẻ tín dụng" → AI says "Không tìm thấy ví thẻ tín dụng"
- ✅ After full fix: "Ăn sáng $40 bằng thẻ tín dụng" → Transaction created in "Credit Card 2 (USD)" wallet correctly

**Root Cause Analysis:**

1. **Missing Vietnamese Keywords:**
   - AI prompt had NO Vietnamese wallet type keywords
   - User says "thẻ tín dụng" → AI doesn't know it means "credit card"
   - AI cannot map Vietnamese input to English wallet types

2. **Incomplete Wallet List Format:**
   - Old format: `"Credit Card 1 (USD)"`
   - No wallet type information in the list
   - AI cannot match by type even if it knew Vietnamese

3. **Cached AI Service Context:**
   - `aiServiceProvider` uses `ref.read()` instead of `ref.watch()`
   - Provider NEVER rebuilds when wallets change
   - AI service initialized once with OLD wallet list
   - Even when wallets update, AI still sees old list

4. **Incorrect Fallback Wallet:**
   - When no active wallet → fallback to "Active Wallet (VND)"
   - AI thinks wallet currency is VND
   - Shows unnecessary conversion: "quy đổi thành 526,316 VND" for USD→USD transaction

5. **Wallet Name Uniqueness Issue (Discovered during investigation):**
   - Database schema had NO UNIQUE constraint on wallet name
   - Multiple wallets could have same name
   - AI matching becomes ambiguous

### 12.2. Solution: Multi-Part Fix

**Part 1: Wallet Name UNIQUE Constraint (v286)**

Added database-level uniqueness:

**File:** `lib/core/database/tables/wallet_table.dart` (line 14)
```dart
// OLD:
TextColumn get name => text().withDefault(const Constant('My Wallet'))();

// NEW:
TextColumn get name => text().withDefault(const Constant('My Wallet')).unique()();
```

**File:** `lib/core/database/app_database.dart` (schema v14→v15)
```dart
// Migration with auto-rename duplicates
if (from < 15) {
  // Step 1: Detect duplicates
  final duplicates = await customSelect(
    'SELECT name, COUNT(*) as count FROM wallets GROUP BY name HAVING count > 1'
  ).get();

  // Step 2: Rename duplicates ("Cash" → "Cash 2", "Cash 3")
  for (final row in duplicates) {
    final duplicateName = row.read<String>('name');
    final walletsWithName = await customSelect(
      'SELECT id FROM wallets WHERE name = ? ORDER BY id',
      variables: [Variable.withString(duplicateName)],
    ).get();

    for (int i = 1; i < walletsWithName.length; i++) {
      final walletId = walletsWithName[i].read<int>('id');
      final newName = '$duplicateName ${i + 1}';
      await customUpdate(
        'UPDATE wallets SET name = ? WHERE id = ?',
        variables: [Variable.withString(newName), Variable.withInt(walletId)],
      );
    }
  }

  // Step 3: Recreate table with UNIQUE constraint
  await customStatement('CREATE TABLE wallets_new AS SELECT * FROM wallets');
  await customStatement('DROP TABLE wallets');
  await m.createTable(wallets);
  await customStatement('INSERT INTO wallets SELECT * FROM wallets_new');
  await customStatement('DROP TABLE wallets_new');
}
```

**File:** `lib/features/wallet/screens/wallet_form_bottom_sheet.dart`
```dart
// UI validation to prevent duplicate names
final allWallets = await walletDao.getAllWallets();
final duplicateName = allWallets.any((w) =>
  w.name.toLowerCase() == newWallet.name.toLowerCase() &&
  w.id != newWallet.id
);

if (duplicateName) {
  toastification.show(
    description: const Text('A wallet with this name already exists...'),
    type: ToastificationType.error,
  );
  return;
}
```

**Part 2: Vietnamese Wallet Type Keywords (v287)**

**File:** `lib/features/ai_chat/data/config/ai_prompts.dart` (lines 158-185)
```dart
static const String walletMatchingRules = '''
WALLET MATCHING:
1. Detect wallet name from user input using keywords:
   - English: "on [wallet]", "to [wallet]", "from [wallet]", ...
   - Vietnamese: "vào [wallet]", "từ [wallet]", "bằng [wallet]", "trả bằng [wallet]"
   - Chinese: "用[wallet]", "在[wallet]"
   - Japanese: "[wallet]で", "[wallet]から"

2. WALLET TYPE KEYWORDS (user may refer to wallet by TYPE instead of name):
   - Cash: "cash", "tiền mặt"
   - Bank Account: "bank", "bank account", "ngân hàng", "tài khoản ngân hàng"
   - Credit Card: "credit card", "thẻ tín dụng", "thẻ"
   - E-Wallet: "e-wallet", "digital wallet", "ví điện tử"
   - Investment: "investment", "đầu tư"
   - Savings: "savings", "tiết kiệm"
   - Insurance: "insurance", "bảo hiểm"

3. Match wallet from AVAILABLE WALLETS list:
   - Format: "Wallet Name (CURRENCY, Type)" - e.g., "Credit Card 1 (USD, Credit Card)"
   - Match by: a) Exact wallet NAME, or b) Partial wallet name, or c) Wallet TYPE
   - Examples:
     * "thẻ tín dụng" → matches wallet with type "Credit Card"
     * "Credit Card" → matches "Credit Card 1" (partial name match)
     * "tiền mặt" → matches wallet with type "Cash"
''';
```

**Part 3: Update Wallet List Format (v287)**

**File:** `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` (line 194)
```dart
// OLD: Only name and currency
final walletNames = allWallets.map((w) => '${w.name} (${w.currency})').toList();

// NEW: Include wallet type
final walletNames = allWallets.map((w) =>
  '${w.name} (${w.currency}, ${w.walletType.displayName})'
).toList();
```

**Part 4: Dynamic AI Context Update (v287)**

**File:** `lib/features/ai_chat/data/services/ai_service.dart`

Added `updateContext()` method to interface:
```dart
abstract class AIService {
  void updateContext({
    String? walletName,
    String? walletCurrency,
    List<String>? wallets,
    double? exchangeRate,
  });
}
```

Made fields mutable in `GeminiService`:
```dart
// Changed from final to mutable
String? walletCurrency;
String? walletName;
double? exchangeRateVndToUsd;
List<String>? wallets;
```

Implemented `updateContext()` in `GeminiService`:
```dart
@override
void updateContext({
  String? walletName,
  String? walletCurrency,
  List<String>? wallets,
  double? exchangeRate,
}) {
  if (walletName != null) this.walletName = walletName;
  if (walletCurrency != null) this.walletCurrency = walletCurrency;
  if (wallets != null) this.wallets = wallets;
  if (exchangeRate != null) exchangeRateVndToUsd = exchangeRate;

  Log.d('✅ Updated AI context: wallet="$walletName" ($walletCurrency), wallets: ${wallets?.length ?? 0}',
    label: 'AI Service');
}
```

**Part 5: Call updateContext() Before Each Message (v287)**

**File:** `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` (lines 438-462)
```dart
// Update AI with current wallet context BEFORE sending message
final activeWallet = _ref.read(activeWalletProvider).valueOrNull;
final allWalletsAsync = _ref.read(allWalletsStreamProvider);
final allWallets = allWalletsAsync.valueOrNull ?? [];
final walletNames = allWallets.map((w) =>
  '${w.name} (${w.currency}, ${w.walletType.displayName})'
).toList();

// CRITICAL: Use first wallet as fallback instead of hardcoded VND
final fallbackWallet = activeWallet ?? (allWallets.isNotEmpty ? allWallets.first : null);

_aiService.updateContext(
  walletName: fallbackWallet?.name ?? 'Active Wallet',
  walletCurrency: fallbackWallet?.currency ?? 'VND',
  wallets: walletNames,
  exchangeRate: cachedRate?.rate,
);
```

**Part 6: 3-Tier Fuzzy Wallet Matching (v287)**

**File:** `lib/features/ai_chat/presentation/riverpod/chat_provider.dart`
```dart
// Priority 1: If AI specified a wallet name, use it
if (aiWalletName != null && aiWalletName.isNotEmpty) {
  final aiWalletLower = aiWalletName.toLowerCase();

  // Tier 1: Exact match
  wallet = allWallets.firstWhereOrNull((w) =>
    w.name.toLowerCase() == aiWalletLower);

  // Tier 2: Partial match (e.g., "Credit Card" matches "Credit Card 1")
  if (wallet == null) {
    wallet = allWallets.firstWhereOrNull((w) =>
      w.name.toLowerCase().contains(aiWalletLower) ||
      aiWalletLower.contains(w.name.toLowerCase()));
  }

  // Tier 3: Wallet type match (e.g., "Credit Card" matches walletType.creditCard)
  if (wallet == null) {
    wallet = allWallets.firstWhereOrNull((w) {
      final typeName = w.walletType.displayName.toLowerCase();
      return typeName == aiWalletLower ||
             typeName.contains(aiWalletLower) ||
             aiWalletLower.contains(typeName);
    });
  }
}
```

### 12.3. Bonus: Disabled State Support for Wallet Type Field

**File:** `lib/core/components/form_fields/field_decoration_helper.dart`
```dart
static Color getBackgroundColor(BuildContext context, bool enabled) {
  final theme = Theme.of(context);
  if (!enabled) {
    return theme.colorScheme.surfaceVariant;
  }
  return theme.colorScheme.surfaceContainerHighest;
}
```

**File:** `lib/features/wallet/presentation/components/wallet_type_selector_field.dart`
```dart
class WalletTypeSelectorField extends StatelessWidget {
  final bool enabled;

  const WalletTypeSelectorField({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.label,
    this.enabled = true,  // Support disabled state
  });
}
```

### 12.4. Testing Results (v288)

**Test:** "Ăn sáng $40 bằng thẻ tín dụng"

**AI Response:**
```
Đã ghi nhận chi tiêu **$40.00 USD** cho **bữa sáng** (**Food & Drinks**) vào ví **Credit Card 2**.
```

**Results:**
- ✅ AI detected "thẻ tín dụng" = Credit Card type
- ✅ AI returned `"wallet":"Credit Card 2"` in JSON
- ✅ Transaction created in correct Credit Card 2 (USD) wallet
- ✅ NO unnecessary VND conversion shown
- ✅ Wallet matching worked with partial name

**User Confirmation:** "Có vẻ đúng rồi" ✅

### 12.5. Code Changes Summary

**Files Modified:**
1. `lib/core/database/tables/wallet_table.dart` - Added UNIQUE constraint
2. `lib/core/database/app_database.dart` - Migration v14→v15 with duplicate handling
3. `lib/features/wallet/screens/wallet_form_bottom_sheet.dart` - Duplicate name validation
4. `lib/features/ai_chat/data/config/ai_prompts.dart` - Vietnamese wallet type keywords
5. `lib/features/ai_chat/data/services/ai_service.dart` - updateContext() method, mutable fields
6. `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` - Dynamic context update, 3-tier matching, wallet list format
7. `lib/core/components/form_fields/field_decoration_helper.dart` - Disabled state support
8. `lib/features/wallet/presentation/components/wallet_type_selector_field.dart` - Enabled parameter
9. `pubspec.yaml` - v0.0.7+286 → v0.0.7+288

### 12.6. Version History

- **v286**: UNIQUE constraint on wallet names + migration
- **v287**: Vietnamese keywords + dynamic context + 3-tier matching
- **v288**: Fallback wallet fix (no VND conversion)

### 12.7. Lessons Learned

1. **Multi-language Support Requires Explicit Keywords** - AI doesn't automatically know "thẻ tín dụng" = "credit card"
2. **Provider Lifecycle Matters** - `ref.read()` vs `ref.watch()` has huge impact on state updates
3. **Context Must Be Dynamic** - Static initialization with cached data causes stale state
4. **Wallet List Format Must Include Type** - Matching by type requires type in the data
5. **Fallback Logic Should Use Real Data** - Don't hardcode fallback currency (VND), use first wallet
6. **Database Constraints Prevent Data Integrity Issues** - UNIQUE constraint prevents duplicate wallet names
7. **3-Tier Fuzzy Matching Improves UX** - Exact → Partial → Type matching handles edge cases

### 12.8. Commit

**Commit:** `a1c1ff9` - feat(ai-chat): Add Vietnamese wallet type detection and fix currency conversion

**STATUS: ✅ RESOLVED**
