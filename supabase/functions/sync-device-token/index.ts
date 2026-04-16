import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// TODO: Sign in with Apple 구현 후 JWT 검증으로 교체 예정
Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: { userId?: string; deviceToken?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { userId, deviceToken } = body;
  if (!userId || !deviceToken) {
    return new Response(
      JSON.stringify({ error: "userId and deviceToken are required" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { error } = await supabase
    .from("user_device_tokens")
    .upsert(
      { user_id: userId, device_token: deviceToken },
      { onConflict: "user_id,device_token" }
    );

  if (error) {
    console.error("upsert error:", error);
    return new Response(JSON.stringify({ error: "DB error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
