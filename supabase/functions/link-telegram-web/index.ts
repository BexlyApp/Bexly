// Web page for linking Telegram account via browser
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createSupabaseClient } from "../_shared/supabase-client.ts";

serve(async (req) => {
  const url = new URL(req.url);
  const telegramId = url.searchParams.get("telegram_id");

  // If no telegram_id, show error
  if (!telegramId) {
    return new Response(
      getErrorHTML("Invalid link", "Missing Telegram ID parameter."),
      {
        headers: { "Content-Type": "text/html" },
        status: 400,
      },
    );
  }

  // Check if user is authenticated via session cookie
  const supabase = createSupabaseClient();
  const authHeader = req.headers.get("cookie");

  // Try to get user from session
  let user = null;
  if (authHeader) {
    const cookies = authHeader.split(";").map(c => c.trim());
    const accessToken = cookies
      .find(c => c.startsWith("sb-access-token="))
      ?.split("=")[1];

    if (accessToken) {
      const { data: { user: authUser } } = await supabase.auth.getUser(
        accessToken,
      );
      user = authUser;
    }
  }

  // If not authenticated, redirect to login
  if (!user) {
    return new Response(
      getLoginHTML(telegramId),
      {
        headers: { "Content-Type": "text/html" },
      },
    );
  }

  // User is authenticated, link the account
  try {
    // Check if already linked
    const { data: existing } = await supabase
      .from("user_integrations")
      .select("*")
      .eq("platform", "telegram")
      .eq("platform_user_id", telegramId)
      .maybeSingle();

    if (existing) {
      if (existing.user_id === user.id) {
        return new Response(
          getSuccessHTML("Already Linked", "Your Telegram account is already linked!"),
          {
            headers: { "Content-Type": "text/html" },
          },
        );
      } else {
        return new Response(
          getErrorHTML(
            "Account Conflict",
            "This Telegram account is already linked to another Bexly account.",
          ),
          {
            headers: { "Content-Type": "text/html" },
            status: 409,
          },
        );
      }
    }

    // Create link
    const { error: insertError } = await supabase
      .from("user_integrations")
      .insert({
        user_id: user.id,
        platform: "telegram",
        platform_user_id: telegramId,
        linked_at: new Date().toISOString(),
        last_activity: new Date().toISOString(),
      });

    if (insertError) {
      throw insertError;
    }

    return new Response(
      getSuccessHTML(
        "Success!",
        "Your Telegram account has been linked successfully. You can now close this window and start using the bot!",
      ),
      {
        headers: { "Content-Type": "text/html" },
      },
    );
  } catch (error) {
    console.error("Error linking account:", error);
    return new Response(
      getErrorHTML("Error", `Failed to link account: ${error}`),
      {
        headers: { "Content-Type": "text/html" },
        status: 500,
      },
    );
  }
});

function getLoginHTML(telegramId: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Link Telegram - Bexly</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 40px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
    }
    .icon {
      width: 80px;
      height: 80px;
      margin: 0 auto 24px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 40px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 12px;
      color: #1a1a1a;
    }
    p {
      color: #666;
      margin-bottom: 32px;
      line-height: 1.5;
    }
    .btn {
      display: inline-block;
      width: 100%;
      padding: 16px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
      font-size: 16px;
      transition: transform 0.2s;
    }
    .btn:hover {
      transform: translateY(-2px);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">🔗</div>
    <h1>Link Telegram Account</h1>
    <p>Login to your Bexly account to link your Telegram bot.</p>
    <a href="https://dos.supabase.co/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(`https://dos.supabase.co/functions/v1/link-telegram-web?telegram_id=${telegramId}`)}" class="btn">
      Login with Google
    </a>
  </div>
</body>
</html>`;
}

function getSuccessHTML(title: string, message: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - Bexly</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 40px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 24px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 12px;
      color: #1a1a1a;
    }
    p {
      color: #666;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✅</div>
    <h1>${title}</h1>
    <p>${message}</p>
  </div>
  <script>
    // Auto close after 3 seconds
    setTimeout(() => {
      window.close();
    }, 3000);
  </script>
</body>
</html>`;
}

function getErrorHTML(title: string, message: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - Bexly</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 40px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 24px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 12px;
      color: #1a1a1a;
    }
    p {
      color: #666;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">❌</div>
    <h1>${title}</h1>
    <p>${message}</p>
  </div>
</body>
</html>`;
}
