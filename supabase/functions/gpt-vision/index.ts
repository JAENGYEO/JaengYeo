import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const PROMPT = `이 사진에서 보이는 식품 또는 생활용품을 분석해줘.
결과는 반드시 아래 JSON 형식의 배열만 반환해. 설명 텍스트 없이 JSON만.
[{ "name": "상품명", "estimatedCategory": "카테고리", "estimatedQuantity": 수량 }]
카테고리는 식재료/생활용품 중 하나.
상품이 없으면 빈 배열 []을 반환.`;

Deno.serve(async (req: Request) => {
  // JWT 검증
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "missing_authorization" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
  console.log("[gpt-vision] auth ok");

  // 요청 파싱
  let imageBase64: string;
  let mimeType: string;
  try {
    const body = await req.json();
    imageBase64 = body.imageBase64;
    mimeType = body.mimeType ?? "image/jpeg";
    if (!imageBase64) throw new Error("missing imageBase64");
  } catch {
    return new Response(JSON.stringify({ error: "invalid_request" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // OpenAI API 호출 (30초 timeout)
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30_000);

  let gptRes: Response;
  try {
    const start = Date.now();
    console.log("[gpt-vision] openai fetch start");

    gptRes = await fetch(OPENAI_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: PROMPT },
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${imageBase64}` },
              },
            ],
          },
        ],
        max_tokens: 1000,
      }),
    });

    clearTimeout(timeoutId);
    console.log(`[gpt-vision] openai fetch done: ${Date.now() - start}ms, status: ${gptRes.status}`);
  } catch (e) {
    clearTimeout(timeoutId);
    if (e instanceof DOMException && e.name === "AbortError") {
      console.log("[gpt-vision] timeout after 30s");
      return new Response(JSON.stringify({ error: "timeout" }), {
        status: 504,
        headers: { "Content-Type": "application/json" },
      });
    }
    throw e;
  }

  if (!gptRes.ok) {
    const errBody = await gptRes.json().catch(() => ({}));
    return new Response(JSON.stringify({ error: "gpt_api_error", detail: errBody }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const gptData = await gptRes.json();
  const text = gptData?.choices?.[0]?.message?.content ?? "[]";

  // JSON 파싱 — 설명 텍스트 섞인 경우 배열 부분만 추출
  let items: unknown[];
  try {
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    items = jsonMatch ? JSON.parse(jsonMatch[0]) : [];
    if (!Array.isArray(items)) items = [];
  } catch {
    items = [];
  }

  return new Response(JSON.stringify({ items }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
