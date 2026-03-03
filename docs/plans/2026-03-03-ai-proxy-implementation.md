# AI Proxy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move OpenAI/Gemini/Claude API keys from client-side `.env` to server-side Supabase Edge Function proxy.

**Architecture:** Single Edge Function `ai-proxy` receives chat/OCR requests from the Flutter app, authenticates via Supabase JWT, then forwards to the correct provider using server-side API keys. The proxy returns a unified response format so the Flutter app doesn't parse provider-specific responses. DOS AI is excluded (already server-side).

**Tech Stack:** Supabase Edge Functions (Deno/TypeScript), Flutter/Dart (HTTP client), Supabase Auth (JWT)

---

### Task 1: Create Edge Function `ai-proxy`

**Files:**
- Create: `supabase/functions/ai-proxy/index.ts`

**Step 1: Create the Edge Function file**

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
};

// Provider defaults
const DEFAULTS = {
  openai: { model: "gpt-4o-mini", chatUrl: "https://api.openai.com/v1/chat/completions" },
  gemini: { model: "gemini-2.5-flash-preview", baseUrl: "https://generativelanguage.googleapis.com/v1beta/models" },
  claude: { model: "claude-sonnet-4-20250514", chatUrl: "https://api.anthropic.com/v1/messages", apiVersion: "2023-06-01" },
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Auth: verify Supabase JWT
    const authHeader = req.headers.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing authorization" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    // Parse request
    const body = await req.json();
    const { provider, action, model, messages, image, prompt, temperature, max_tokens } = body;

    if (!provider || !action) {
      return jsonResponse({ error: "Missing provider or action" }, 400);
    }

    // Route to provider
    let result: string | null = null;

    if (action === "chat") {
      if (!messages || !Array.isArray(messages)) {
        return jsonResponse({ error: "Missing messages array" }, 400);
      }
      result = await handleChat(provider, model, messages, temperature, max_tokens);
    } else if (action === "ocr") {
      if (!image) {
        return jsonResponse({ error: "Missing image" }, 400);
      }
      result = await handleOcr(provider, model, image, prompt || "");
    } else {
      return jsonResponse({ error: `Unknown action: ${action}` }, 400);
    }

    if (result === null) {
      return jsonResponse({ error: "Provider returned no response" }, 502);
    }

    return jsonResponse({ content: result });
  } catch (error) {
    console.error("ai-proxy error:", error);
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});

// ── Chat handlers ──

async function handleChat(
  provider: string,
  model: string | undefined,
  messages: Array<{ role: string; content: string }>,
  temperature?: number,
  maxTokens?: number,
): Promise<string | null> {
  switch (provider) {
    case "openai":
      return chatOpenAI(model || DEFAULTS.openai.model, messages, temperature ?? 0.3, maxTokens ?? 2000);
    case "gemini":
      return chatGemini(model || DEFAULTS.gemini.model, messages, temperature ?? 0.3, maxTokens ?? 2000);
    case "claude":
      return chatClaude(model || DEFAULTS.claude.model, messages, temperature ?? 0.3, maxTokens ?? 2000);
    default:
      throw new Error(`Unknown chat provider: ${provider}`);
  }
}

async function chatOpenAI(
  model: string,
  messages: Array<{ role: string; content: string }>,
  temperature: number,
  maxTokens: number,
): Promise<string | null> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not configured on server");

  const response = await fetch(DEFAULTS.openai.chatUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ model, messages, temperature, max_tokens: maxTokens }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OpenAI ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content?.trim() || null;
}

async function chatGemini(
  model: string,
  messages: Array<{ role: string; content: string }>,
  temperature: number,
  maxTokens: number,
): Promise<string | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY not configured on server");

  // Convert OpenAI messages format to Gemini format
  const systemParts = messages.filter((m) => m.role === "system");
  const chatParts = messages.filter((m) => m.role !== "system");

  const geminiContents = chatParts.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));

  const requestBody: Record<string, unknown> = {
    contents: geminiContents,
    generationConfig: { temperature, maxOutputTokens: maxTokens },
  };

  if (systemParts.length > 0) {
    requestBody.systemInstruction = {
      parts: [{ text: systemParts.map((s) => s.content).join("\n") }],
    };
  }

  const url = `${DEFAULTS.gemini.baseUrl}/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Gemini ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || null;
}

async function chatClaude(
  model: string,
  messages: Array<{ role: string; content: string }>,
  temperature: number,
  maxTokens: number,
): Promise<string | null> {
  const apiKey = Deno.env.get("CLAUDE_API_KEY");
  if (!apiKey) throw new Error("CLAUDE_API_KEY not configured on server");

  // Extract system message
  const systemParts = messages.filter((m) => m.role === "system");
  const chatMessages = messages.filter((m) => m.role !== "system");

  const requestBody: Record<string, unknown> = {
    model,
    messages: chatMessages,
    max_tokens: maxTokens,
    temperature,
  };

  if (systemParts.length > 0) {
    requestBody.system = systemParts.map((s) => s.content).join("\n");
  }

  const response = await fetch(DEFAULTS.claude.chatUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": DEFAULTS.claude.apiVersion,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Claude ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.content?.[0]?.text?.trim() || null;
}

// ── OCR handlers ──

async function handleOcr(
  provider: string,
  model: string | undefined,
  image: string,
  prompt: string,
): Promise<string | null> {
  switch (provider) {
    case "gemini":
      return ocrGemini(model || DEFAULTS.gemini.model, image, prompt);
    case "claude":
      return ocrClaude(model || DEFAULTS.claude.model, image, prompt);
    default:
      throw new Error(`OCR not supported for provider: ${provider}`);
  }
}

async function ocrGemini(model: string, image: string, prompt: string): Promise<string | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY not configured on server");

  const url = `${DEFAULTS.gemini.baseUrl}/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{
        parts: [
          { text: prompt },
          { inlineData: { mimeType: "image/jpeg", data: image } },
        ],
      }],
      generationConfig: {
        response_mime_type: "application/json",
        temperature: 0.2,
      },
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Gemini OCR ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || null;
}

async function ocrClaude(model: string, image: string, prompt: string): Promise<string | null> {
  const apiKey = Deno.env.get("CLAUDE_API_KEY");
  if (!apiKey) throw new Error("CLAUDE_API_KEY not configured on server");

  const response = await fetch(DEFAULTS.claude.chatUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": DEFAULTS.claude.apiVersion,
    },
    body: JSON.stringify({
      model,
      max_tokens: 1024,
      temperature: 0.2,
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
          { type: "text", text: prompt },
        ],
      }],
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Claude OCR ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.content?.[0]?.text?.trim() || null;
}

// ── Helpers ──

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

**Step 2: Deploy Edge Function and set secrets**

```bash
cd supabase
npx supabase functions deploy ai-proxy --project-ref gulptwduchsjcsbndmua
npx supabase secrets set OPENAI_API_KEY="sk-proj-..." --project-ref gulptwduchsjcsbndmua
npx supabase secrets set GEMINI_API_KEY="AIzaSy..." --project-ref gulptwduchsjcsbndmua
npx supabase secrets set CLAUDE_API_KEY="..." --project-ref gulptwduchsjcsbndmua
```

**Step 3: Commit**

```bash
git add supabase/functions/ai-proxy/index.ts
git commit -m "feat: add ai-proxy edge function for server-side AI key management"
```

---

### Task 2: Add proxy URL helper to llm_config.dart

**Files:**
- Modify: `lib/core/config/llm_config.dart`

**Step 1: Add proxy URL getter and auth token helper**

Add these getters to `LLMDefaultConfig`:

```dart
/// Supabase Edge Function proxy URL for AI providers.
/// Eliminates need for client-side API keys.
static String get proxyUrl => '${SupabaseConfig.url}/functions/v1/ai-proxy';

/// Get current Supabase access token for proxy auth.
/// Returns null if user is not authenticated.
static String? get proxyAccessToken =>
    Supabase.instance.client.auth.currentSession?.accessToken;
```

Add required imports:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bexly/core/config/supabase_config.dart';
```

**Step 2: Commit**

```bash
git add lib/core/config/llm_config.dart
git commit -m "feat: add AI proxy URL and auth token to LLMDefaultConfig"
```

---

### Task 3: Update OpenAIService to use proxy

**Files:**
- Modify: `lib/features/ai_chat/data/services/ai_service.dart` (OpenAIService section, ~lines 59-270)

**Step 1: Update sendMessage to route through proxy**

In `OpenAIService.sendMessage()` (around line 149), replace the HTTP call section.

Change the URL and headers from:
```dart
final url = Uri.parse('$baseUrl/chat/completions');
// ...
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $apiKey',
},
body: jsonEncode({
  'model': model,
  'messages': messages,
  'temperature': 0.3,
  'response_format': {'type': 'text'},
  'max_tokens': 2000,
}),
```

To:
```dart
final token = LLMDefaultConfig.proxyAccessToken;
if (token == null) throw Exception('Not authenticated — cannot use AI proxy');

final url = Uri.parse(LLMDefaultConfig.proxyUrl);
// ...
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
},
body: jsonEncode({
  'provider': 'openai',
  'action': 'chat',
  'model': model,
  'messages': messages,
  'temperature': 0.3,
  'max_tokens': 2000,
}),
```

Change response parsing from:
```dart
final data = jsonDecode(response.body);
final content = data['choices'][0]['message']['content'] as String;
```

To:
```dart
final data = jsonDecode(response.body);
if (data['error'] != null) throw Exception(data['error']);
final content = data['content'] as String;
```

**Step 2: Commit**

```bash
git add lib/features/ai_chat/data/services/ai_service.dart
git commit -m "feat: route OpenAIService through ai-proxy edge function"
```

---

### Task 4: Update GeminiService to use proxy

**Files:**
- Modify: `lib/features/ai_chat/data/services/ai_service.dart` (GeminiService section, ~lines 273-540)

**Step 1: Convert GeminiService from SDK to HTTP through proxy**

Replace the `sendMessage` implementation. Currently it uses `google_generative_ai` SDK
(`GenerativeModel`, `Content.text()`, `startChat()`). Convert to HTTP POST like OpenAI.

Key changes:
1. Change `_conversationHistory` from `List<Content>` to `List<Map<String, String>>`
2. Replace SDK calls with `http.post()` to proxy URL
3. Use `LLMDefaultConfig.proxyAccessToken` for auth
4. Send `provider: "gemini"` in request body

The conversation history management changes from:
```dart
_conversationHistory.add(Content.text(message));
_conversationHistory.add(Content.model([TextPart(content)]));
```

To:
```dart
_conversationHistory.add({'role': 'user', 'content': message});
_conversationHistory.add({'role': 'assistant', 'content': content});
```

The request becomes the same format as OpenAI but with `provider: "gemini"`.

**Step 2: Commit**

```bash
git add lib/features/ai_chat/data/services/ai_service.dart
git commit -m "feat: route GeminiService through ai-proxy edge function"
```

---

### Task 5: Update GeminiOcrProvider to use proxy

**Files:**
- Modify: `lib/features/receipt_scanner/data/services/providers/gemini_ocr_provider.dart`

**Step 1: Replace direct Gemini API call with proxy**

Change `analyzeReceipt` to POST to proxy with:
```dart
final token = LLMDefaultConfig.proxyAccessToken;
if (token == null) throw Exception('Not authenticated — cannot use AI proxy');

final response = await http.post(
  Uri.parse(LLMDefaultConfig.proxyUrl),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'provider': 'gemini',
    'action': 'ocr',
    'model': _model,
    'image': base64Image,
    'prompt': prompt,
  }),
).timeout(const Duration(seconds: 45));
```

Response parsing changes from:
```dart
final jsonResponse = jsonDecode(response.body);
final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
```

To:
```dart
final jsonResponse = jsonDecode(response.body);
if (jsonResponse['error'] != null) throw Exception(jsonResponse['error']);
final text = jsonResponse['content'] as String;
```

Remove `apiKey` constructor parameter (no longer needed).

**Step 2: Commit**

```bash
git add lib/features/receipt_scanner/data/services/providers/gemini_ocr_provider.dart
git commit -m "feat: route GeminiOcrProvider through ai-proxy"
```

---

### Task 6: Update ClaudeOcrProvider to use proxy

**Files:**
- Modify: `lib/features/receipt_scanner/data/services/providers/claude_ocr_provider.dart`

**Step 1: Replace direct Anthropic API call with proxy**

Same pattern as Task 5 but with `provider: "claude"`.

Remove `apiKey` constructor parameter.

**Step 2: Commit**

```bash
git add lib/features/receipt_scanner/data/services/providers/claude_ocr_provider.dart
git commit -m "feat: route ClaudeOcrProvider through ai-proxy"
```

---

### Task 7: Update BackgroundAIService to use proxy

**Files:**
- Modify: `lib/core/services/ai/background_ai_service.dart`

**Step 1: Update OpenAI and Gemini paths to use proxy**

In the `complete()` method:
- `AIProvider.openai` case: use proxy instead of direct `api.openai.com` call
- `AIProvider.gemini` case: use proxy instead of `google_generative_ai` SDK
- `AIProvider.custom` case: keep unchanged (DOS AI is already server-side)

Replace `_completeViaGemini` with HTTP call through proxy (same format as OpenAI).

For the fallback logic: if primary provider fails and Gemini key check
(`LLMDefaultConfig.geminiApiKey.isNotEmpty`), replace with auth check
(`LLMDefaultConfig.proxyAccessToken != null`).

**Step 2: Commit**

```bash
git add lib/core/services/ai/background_ai_service.dart
git commit -m "feat: route BackgroundAIService through ai-proxy for OpenAI/Gemini"
```

---

### Task 8: Update chat_provider.dart and receipt_scanner_provider.dart

**Files:**
- Modify: `lib/features/ai_chat/presentation/riverpod/chat_provider.dart`
- Modify: `lib/features/receipt_scanner/presentation/riverpod/receipt_scanner_provider.dart`

**Step 1: Update chat_provider.dart**

In the `aiServiceProvider` provider:
- For `AIModel.openAI`: remove `apiKey` parameter (service gets token internally)
- For `AIModel.gemini`: remove `apiKey` parameter
- For `AIModel.dosAI`: keep unchanged

In the fallback logic (`_getOrCreateFallbackGeminiService`):
- Remove `apiKey` parameter from `GeminiService()` constructor

**Step 2: Update receipt_scanner_provider.dart**

Remove `dotenv.env['GEMINI_API_KEY']`, `dotenv.env['OPENAI_API_KEY']`,
`dotenv.env['CLAUDE_API_KEY']` reads. The OCR providers no longer need API keys.

**Step 3: Commit**

```bash
git add lib/features/ai_chat/presentation/riverpod/chat_provider.dart \
        lib/features/receipt_scanner/presentation/riverpod/receipt_scanner_provider.dart
git commit -m "feat: remove API key passing from providers (now server-side)"
```

---

### Task 9: Clean up .env and llm_config.dart

**Files:**
- Modify: `.env` (remove AI keys)
- Modify: `lib/core/config/llm_config.dart` (remove key getters)

**Step 1: Remove AI keys from .env**

Remove these lines from `.env`:
```
OPENAI_API_KEY=...
GEMINI_API_KEY=...
CLAUDE_API_KEY=...
```

Keep these (still needed):
```
BEXLY_FREE_AI_KEY=...
BEXLY_FREE_AI_URL=...
STRIPE_PUBLISHABLE_KEY=...
SUPABASE_PUBLISHABLE_KEY=...
SUPABASE_URL=...
```

**Step 2: Update llm_config.dart**

Remove (or mark deprecated) `apiKey` and `geminiApiKey` getters since they're no
longer used. Keep `customApiKey` (DOS AI still needs it).

**Step 3: Commit**

```bash
git add lib/core/config/llm_config.dart
git commit -m "security: remove OpenAI/Gemini/Claude API keys from client .env"
```

---

### Task 10: Test on emulator

**Step 1: Run the app**

```bash
flutter run -d emulator-5554
```

**Step 2: Test AI chat**

1. Open AI chat screen
2. Select OpenAI provider → send message → verify response
3. Select Gemini provider → send message → verify response
4. Select DOS AI → send message → verify still works (unchanged)

**Step 3: Test receipt scanner**

1. Open receipt scanner
2. Take/select a receipt photo
3. Test with Gemini OCR provider
4. Test with Claude OCR provider (if key is configured)

**Step 4: Check logs for errors**

```bash
adb logcat -s flutter | grep -i "proxy\|error\|401\|403"
```

---

### Task 11: Final commit and summary

**Step 1: Verify all changes**

```bash
git status
flutter analyze
```

**Step 2: Squash or verify commit history is clean**

Ensure all commits from Tasks 1-9 are present and logical.
