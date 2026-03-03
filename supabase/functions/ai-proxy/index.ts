import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, content-type, x-client-info, apikey",
};

const DEFAULTS = {
  openai: {
    model: "gpt-4o-mini",
    chatUrl: "https://api.openai.com/v1/chat/completions",
  },
  gemini: {
    model: "gemini-2.5-flash-preview",
    baseUrl:
      "https://generativelanguage.googleapis.com/v1beta/models",
  },
  claude: {
    model: "claude-sonnet-4-20250514",
    chatUrl: "https://api.anthropic.com/v1/messages",
    apiVersion: "2023-06-01",
  },
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Verify Supabase JWT
    const authHeader = req.headers.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing authorization" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const { provider, action, model, messages, image, prompt, temperature, max_tokens } = body;

    if (!provider || !action) {
      return jsonResponse({ error: "Missing provider or action" }, 400);
    }

    let result: string | null = null;

    if (action === "chat") {
      if (!messages || !Array.isArray(messages)) {
        return jsonResponse({ error: "Missing messages array" }, 400);
      }
      result = await handleChat(
        provider,
        model,
        messages,
        temperature,
        max_tokens,
      );
    } else if (action === "ocr") {
      if (!image) {
        return jsonResponse({ error: "Missing image" }, 400);
      }
      // Extract prompt from messages array if provided, otherwise use prompt field
      const ocrPrompt = prompt || (messages && messages.length > 0 ? messages[0].content : "");
      result = await handleOcr(provider, model, image, ocrPrompt, temperature, max_tokens);
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

// ── Chat ──

async function handleChat(
  provider: string,
  model: string | undefined,
  messages: Array<{ role: string; content: string }>,
  temperature?: number,
  maxTokens?: number,
): Promise<string | null> {
  switch (provider) {
    case "openai":
      return chatOpenAI(
        model || DEFAULTS.openai.model,
        messages,
        temperature ?? 0.3,
        maxTokens ?? 2000,
      );
    case "gemini":
      return chatGemini(
        model || DEFAULTS.gemini.model,
        messages,
        temperature ?? 0.3,
        maxTokens ?? 2000,
      );
    case "claude":
      return chatClaude(
        model || DEFAULTS.claude.model,
        messages,
        temperature ?? 0.3,
        maxTokens ?? 2000,
      );
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
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature,
      max_tokens: maxTokens,
    }),
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

  // Convert OpenAI messages format → Gemini format
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

// ── OCR ──

async function handleOcr(
  provider: string,
  model: string | undefined,
  image: string,
  prompt: string,
  temperature?: number,
  maxTokens?: number,
): Promise<string | null> {
  switch (provider) {
    case "openai":
      return ocrOpenAI(model || "gpt-4o", image, prompt, temperature ?? 0.2);
    case "gemini":
      return ocrGemini(model || DEFAULTS.gemini.model, image, prompt);
    case "claude":
      return ocrClaude(model || DEFAULTS.claude.model, image, prompt, maxTokens ?? 1024);
    default:
      throw new Error(`OCR not supported for provider: ${provider}`);
  }
}

async function ocrOpenAI(
  model: string,
  image: string,
  prompt: string,
  temperature: number,
): Promise<string | null> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not configured on server");

  const response = await fetch(DEFAULTS.openai.chatUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            {
              type: "image_url",
              image_url: { url: `data:image/jpeg;base64,${image}` },
            },
          ],
        },
      ],
      response_format: { type: "json_object" },
      temperature,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OpenAI OCR ${response.status}: ${err}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content?.trim() || null;
}

async function ocrGemini(
  model: string,
  image: string,
  prompt: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY not configured on server");

  const url = `${DEFAULTS.gemini.baseUrl}/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: prompt },
            { inlineData: { mimeType: "image/jpeg", data: image } },
          ],
        },
      ],
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

async function ocrClaude(
  model: string,
  image: string,
  prompt: string,
  maxTokens: number,
): Promise<string | null> {
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
      max_tokens: maxTokens,
      temperature: 0.2,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image,
              },
            },
            { type: "text", text: prompt },
          ],
        },
      ],
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

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
