import type { ParsedTransaction, UserCategory, AIProvider } from "./types.ts";
import { AI_CONFIG } from "./types.ts";

// Build dynamic prompt with user's categories
function buildDynamicPrompt(
  userCategories: UserCategory[],
  walletCurrency?: string,
): string {
  const expenseCategories = userCategories
    .filter((c) => c.transactionType === "expense")
    .map((c) => c.title);

  const incomeCategories = userCategories
    .filter((c) => c.transactionType === "income")
    .map((c) => c.title);

  const expenseCatList = expenseCategories.length > 0
    ? expenseCategories.join("|")
    : "Other";
  const incomeCatList = incomeCategories.length > 0
    ? incomeCategories.join("|")
    : "Other Income";

  return `Parse→JSON.{"action":"create_expense"|"create_income"|"none","amount":num,"currency":"VND"|"USD"|null,"lang":"vi"|"en","desc":"str","cat":"EXACT_CATEGORY_NAME","time":"TIME_HINT"}
k=×1000,tr=×1000000→VND.$→USD.No symbol→null.

⚠️CRITICAL CATEGORY RULES:
1. EXPENSE categories: ${expenseCatList}
2. INCOME categories: ${incomeCatList}
3. cat MUST be EXACTLY one of the names above! Copy the name EXACTLY including case!
4. If no good match, use first expense category for expenses, first income category for income
5. NEVER use generic names like "Shopping", "Food" unless they're in the list above!
6. NEVER make up category names!

⏰TIME EXTRACTION (time field):
- "ăn sáng/breakfast/早餐"→"morning" (7:00)
- "ăn trưa/lunch/午餐"→"noon" (12:00)
- "ăn chiều/snack"→"afternoon" (15:00)
- "ăn tối/dinner/晚餐"→"evening" (19:00)
- "đêm qua/last night"→"yesterday_night"
- "hôm qua/yesterday"→"yesterday"
- "tuần trước/last week"→"last_week"
- "tháng trước/last month"→"last_month"
- "sáng nay/this morning"→"morning"
- "tối qua/yesterday evening"→"yesterday_evening"
- Explicit time "lúc 3h/at 3pm"→"15:00"
- No time hint→null

Examples:
"50k ăn sáng"→{"action":"create_expense","amount":50000,"currency":"VND","lang":"vi","desc":"ăn sáng","cat":"${
    expenseCategories[0] || "Other"
  }","time":"morning"}
"lunch $20"→{"action":"create_expense","amount":20,"currency":"USD","lang":"en","desc":"lunch","cat":"${
    expenseCategories[0] || "Other"
  }","time":"noon"}
"hi"→{"action":"none","amount":0,"currency":null,"lang":"en","desc":"","cat":"","time":null}`;
}

// Parse with Gemini
async function parseWithGemini(
  text: string,
  dynamicPrompt: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    console.error("Gemini API key not configured");
    return null;
  }

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${AI_CONFIG.models.gemini}:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: dynamicPrompt }],
      },
      contents: [{
        role: "user",
        parts: [{ text: text }],
      }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 300,
        candidateCount: 1,
      },
    }),
  });

  if (!response.ok) {
    console.error("Gemini API error:", response.status, await response.text());
    return null;
  }

  const data = await response.json();
  const result = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  const finishReason = data.candidates?.[0]?.finishReason;

  if (finishReason && finishReason !== "STOP") {
    console.warn("Gemini finish reason:", finishReason);
  }

  return result || null;
}

// Parse with OpenAI
async function parseWithOpenAI(
  text: string,
  dynamicPrompt: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    console.error("OpenAI API key not configured");
    return null;
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: AI_CONFIG.models.openai,
      messages: [
        { role: "system", content: dynamicPrompt },
        { role: "user", content: `Parse this message: "${text}"` },
      ],
      temperature: 0.1,
      max_tokens: 500,
    }),
  });

  if (!response.ok) {
    console.error("OpenAI API error:", response.status, await response.text());
    return null;
  }

  const data = await response.json();
  return data.choices[0]?.message?.content?.trim() || null;
}

// Parse with Claude
async function parseWithClaude(
  text: string,
  dynamicPrompt: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("CLAUDE_API_KEY");
  if (!apiKey) {
    console.error("Claude API key not configured");
    return null;
  }

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: AI_CONFIG.models.claude,
      max_tokens: 300,
      system: dynamicPrompt,
      messages: [
        { role: "user", content: text },
      ],
    }),
  });

  if (!response.ok) {
    console.error("Claude API error:", response.status, await response.text());
    return null;
  }

  const data = await response.json();
  return data.content[0]?.text?.trim() || null;
}

// Main AI parsing function
export async function parseTransactionWithAI(
  text: string,
  userCategories: UserCategory[],
  walletCurrency?: string,
  provider: AIProvider = AI_CONFIG.provider,
): Promise<ParsedTransaction | null> {
  try {
    let response: string | null = null;

    const dynamicPrompt = buildDynamicPrompt(userCategories, walletCurrency);
    console.log(
      "Using dynamic prompt with user categories:",
      userCategories.map((c) => c.title).slice(0, 10),
      "...",
      "wallet:",
      walletCurrency,
    );

    // Use configured AI provider
    switch (provider) {
      case "gemini":
        response = await parseWithGemini(text, dynamicPrompt);
        break;
      case "openai":
        response = await parseWithOpenAI(text, dynamicPrompt);
        break;
      case "claude":
        response = await parseWithClaude(text, dynamicPrompt);
        break;
      default:
        console.error("Unknown AI provider:", provider);
        return null;
    }

    if (!response) {
      console.log("No response from AI");
      return null;
    }

    console.log(`${provider} response:`, response);

    // Parse JSON from response
    const jsonMatch = response.match(/\{[^}]+\}/);
    if (!jsonMatch) {
      console.error("No JSON found in AI response");
      return null;
    }

    const parsed = JSON.parse(jsonMatch[0]);

    // Check if action is "none"
    if (parsed.action === "none") {
      return null;
    }

    // Convert action to type
    const type = parsed.action === "create_expense" ? "expense" : "income";

    return {
      type,
      amount: parsed.amount,
      currency: parsed.currency,
      category: parsed.cat,
      description: parsed.desc,
      responseText: `${type === "expense" ? "💸" : "💰"} ${
        parsed.lang === "vi" ? "Đã phát hiện" : "Detected"
      } ${type}!`,
      language: parsed.lang || "en",
      datetime: parsed.time || null,
    };
  } catch (e) {
    console.error("Error parsing transaction with AI:", e);
    return null;
  }
}
