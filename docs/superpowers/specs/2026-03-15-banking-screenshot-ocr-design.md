# Banking Screenshot OCR — Multi-Transaction Extraction

## Goal
When a user sends a banking app screenshot to AI Chat, extract ALL visible transactions, deduplicate against existing data, and let the user bulk-create or review in pending queue — with quick-action buttons for zero-typing UX.

## Architecture

### Flow
```
User sends banking screenshot to AI Chat
  → OCR provider extracts ALL transactions (JSON array)
  → Dedupe against local DB (amount + date ± 1 day + description similarity)
  → AI displays summary with quick-action buttons:
      [✅ Add all N to {wallet}]  [📋 Review in pending]
  → User taps button or types custom instruction
  → Execute: bulk create OR add to pending queue
```

### What Changes

| Component | Change |
|-----------|--------|
| `OcrProvider` interface | New method `analyzeScreenshot()` returning `List<ReceiptScanResult>` |
| `DosAiOcrProvider` | Add multi-transaction prompt + array JSON parsing |
| `GeminiOcrProvider` | Same |
| `FallbackOcrProvider` | Delegate to new method |
| `ReceiptScannerService` | New `analyzeScreenshot()` that detects image type (receipt vs banking screenshot) |
| `chat_provider.dart` | Handle multi-transaction OCR result, dedupe, show buttons, bulk create |
| `ChatMessage` model | Add `quickActions` field for inline buttons |
| `ai_chat_screen.dart` | Render quick-action buttons on messages |
| `PendingTransactionDao` | Reuse existing SMS pending queue for screenshot transactions |

### What Stays the Same
- Single receipt/invoice scanning (existing `analyzeReceipt()` unchanged)
- Receipt scanner screen (standalone feature, not affected)
- OCR provider selection and fallback logic
- Transaction creation logic (`_createTransactionFromAction`)

## Design Details

### 1. Image Type Detection

The OCR provider needs to know whether the image is a receipt or a banking screenshot to use the right prompt. Detection strategy:

**Approach: Let the VLM decide.** Send a single prompt that says "If this is a banking app screenshot with multiple transactions, extract ALL as a JSON array. If it's a receipt/invoice, extract as single JSON object." The response format tells us which case it is.

No separate classification step needed — the VLM already sees the image and can branch internally.

### 2. Multi-Transaction OCR Prompt

```
Analyze this image and extract transaction information.

CASE 1 — Banking app screenshot (list of transactions):
Return a JSON ARRAY of ALL visible transactions:
[
  {"amount": 261590, "currency": "VND", "merchant": "Apple.com/Bill", "category": "Entertainment", "date": "2026-03-15", "payment_method": "Bank Transfer"},
  {"amount": 9000, "currency": "VND", "merchant": "Grab Taxi", "category": "Transportation", "date": "2026-03-15", "payment_method": "Bank Transfer"},
  ...
]

CASE 2 — Receipt or invoice (single transaction):
Return a single JSON OBJECT (existing format):
{"amount": 5727200, "currency": "VND", ...}

RULES:
- amount: number only (no currency symbols, no dots/commas)
- currency: ISO code from context (VND, USD, etc.)
- merchant: clean readable name (Title Case, complete truncated words)
- category: one of [Food & Drinks, Transportation, Shopping, Entertainment, Healthcare, Utilities, Software, Streaming, Education, Housing, Other]
- date: YYYY-MM-DD (use today if only "HÔM NAY" / "TODAY" visible, yesterday for "HÔM QUA")
- Detect income vs expense from context (green = income, red = expense, +/- signs)
- Return ONLY valid JSON, no markdown, no explanation
```

### 3. Response Parsing

```dart
// Parse OCR response — detect array vs object
dynamic parsed = jsonDecode(sanitizedResponse);
if (parsed is List) {
  // Banking screenshot: multiple transactions
  return parsed.map((e) => ReceiptScanResult.fromJson(e)).toList();
} else if (parsed is Map) {
  // Single receipt
  return [ReceiptScanResult.fromJson(parsed)];
}
```

### 4. Deduplication

Code-only, no LLM needed. Run against local transaction DB:

```dart
bool isDuplicate(ReceiptScanResult scanned, TransactionModel existing) {
  // 1. Amount must match exactly
  if (scanned.amount != existing.amount) return false;

  // 2. Date within ±1 day
  final dayDiff = scanned.date.difference(existing.date).inDays.abs();
  if (dayDiff > 1) return false;

  // 3. Description similarity (lowercase contains check)
  final a = scanned.merchant.toLowerCase();
  final b = existing.title.toLowerCase();
  if (a.contains(b) || b.contains(a)) return true;

  // Also check with normalized keywords (remove common words)
  return _fuzzyMatch(a, b, threshold: 0.7);
}
```

### 5. Quick Action Buttons in Chat

Add `quickActions` to `ChatMessage`:

```dart
class QuickAction {
  final String label;     // "✅ Thêm tất cả 4 vào My VND Wallet"
  final String actionId;  // "bulk_create_all"
  final Map<String, dynamic>? payload;  // wallet, transactions, etc.
}

class ChatMessage {
  // ... existing fields ...
  final List<QuickAction>? quickActions;
}
```

UI renders as horizontal/vertical buttons below the message. On tap → send as user action (not as text message) → chat_provider handles it.

### 6. Chat Provider Flow

```dart
// In sendMessage(), after OCR returns multi-transaction result:
if (ocrResults.length > 1) {
  // Banking screenshot detected
  final dedupedResults = _deduplicateAgainstDb(ocrResults);
  final skippedCount = ocrResults.length - dedupedResults.length;

  // Store results temporarily for quick action handling
  _pendingScreenshotTransactions = dedupedResults;

  // Build AI message with quick actions
  final walletName = activeWallet?.name ?? 'My VND Wallet';
  final msg = ChatMessage(
    content: '🔍 Đã quét **${ocrResults.length} giao dịch** '
             '${skippedCount > 0 ? "(bỏ $skippedCount trùng). " : ". "}'
             '**${dedupedResults.length} giao dịch mới** sẵn sàng.',
    quickActions: [
      QuickAction(
        label: '✅ Thêm tất cả ${dedupedResults.length} vào $walletName',
        actionId: 'screenshot_bulk_create',
      ),
      QuickAction(
        label: '📋 Duyệt ở danh sách chờ',
        actionId: 'screenshot_to_pending',
      ),
    ],
  );
}

// Handle quick action tap:
case 'screenshot_bulk_create':
  for (final txn in _pendingScreenshotTransactions) {
    await _createTransactionFromAction(txn.toActionMap());
  }
  // Show confirmation: "✅ Đã thêm 4 giao dịch vào My VND Wallet"

case 'screenshot_to_pending':
  for (final txn in _pendingScreenshotTransactions) {
    await pendingDao.addPendingTransaction(txn.toPendingModel());
  }
  // Show confirmation: "📋 Đã đưa 4 giao dịch vào danh sách chờ"
```

### 7. User Can Still Type

If user doesn't tap a button but types instead (e.g., "thêm vào ví Credit Card", "bỏ cái Grab"), the pending screenshot transactions are still in memory. The AI processes the text command against the stored list.

## Edge Cases

| Case | Handling |
|------|----------|
| All transactions are duplicates | "Đã quét 6 giao dịch nhưng tất cả đã có trong ví. Không có giao dịch mới." |
| Image is neither receipt nor banking screenshot | Fallback to existing behavior: "Quét ảnh không thành công" |
| OCR returns empty array | Same error message |
| User sends screenshot but also types text | Text takes priority as context for the AI |
| Quick action buttons expire after new message | Mark as disabled/hidden after user sends any new message |
| Income transactions (green amounts) | Set `isIncome: true` in action, use income category |

## Files to Create/Modify

**Modify:**
- `lib/features/receipt_scanner/data/services/providers/ocr_provider.dart` — add `analyzeScreenshot()`
- `lib/features/receipt_scanner/data/services/providers/dos_ai_ocr_provider.dart` — multi-txn prompt
- `lib/features/receipt_scanner/data/services/providers/gemini_ocr_provider.dart` — multi-txn prompt
- `lib/features/receipt_scanner/data/services/providers/fallback_ocr_provider.dart` — delegate
- `lib/features/receipt_scanner/data/services/receipt_scanner_service.dart` — new method
- `lib/features/ai_chat/domain/models/chat_message.dart` — add quickActions field
- `lib/features/ai_chat/presentation/riverpod/chat_provider.dart` — multi-txn flow + quick action handler
- `lib/features/ai_chat/presentation/screens/ai_chat_screen.dart` — render quick action buttons

**No new files needed** — reuse existing architecture, just extend it.
