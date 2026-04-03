import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_API_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const PROMPT = `이 사진에서 보이는 식품 또는 생활용품을 분석해줘.
결과는 반드시 아래 JSON 형식의 배열만 반환해. 설명 텍스트 없이 JSON만.
[{ "name": "상품명", "estimatedCategory": "카테고리", "estimatedQuantity": 수량 }]
카테고리는 채소/육류/해산물/유제품/음료/주류/조미료/향신료/디저트/과자/곡류/견과류/기타 중 하나.
상품이 없으면 빈 배열 []을 반환.`;

Deno.serve(async (req: Request) => {
  // JWT 유효성 검증 — Authorization 헤더 존재 여부 + 실제 토큰 검증
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

  // Gemini API 호출
  const geminiRes = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: PROMPT },
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
          ],
        },
      ],
    }),
  });

  if (!geminiRes.ok) {
    return new Response(JSON.stringify({ error: "gemini_api_error" }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const geminiData = await geminiRes.json();
  const text = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "[]";

  // JSON 파싱
  let items: unknown[];
  try {
    const cleaned = text.replace(/```json|```/g, "").trim();
    items = JSON.parse(cleaned);
    if (!Array.isArray(items)) items = [];
  } catch {
    items = [];
  }

  return new Response(JSON.stringify({ items }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
