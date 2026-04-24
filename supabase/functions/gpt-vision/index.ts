import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const VISION_PROMPT = `이 사진에서 보이는 물건을 분석해줘.
결과는 반드시 아래 JSON 형식의 배열만 반환해. 설명 텍스트 없이 JSON만.
[{ "name": "상품명", "estimatedCategory": "카테고리", "estimatedQuantity": 수량 }]
카테고리 규칙: 음식/식품/재료이면 "식재료", 그 외 모든 물건은 "생활용품".
사진에 아무것도 없을 경우에만 빈 배열 []을 반환.`;

const RECEIPT_PROMPT = (ocrText: string) =>
  `아래는 영수증에서 추출한 텍스트야.
텍스트가 영수증이 아니거나 상품 목록을 추출할 수 없으면 빈 배열 []만 반환해.
영수증인 경우에만 구매한 상품 목록을 분석해서 JSON 배열로 반환해줘.
설명 텍스트 없이 JSON만 반환해.
[{ "name": "상품명", "estimatedCategory": "카테고리", "estimatedQuantity": 수량 }]
카테고리 규칙: 음식/식품/재료이면 "식재료", 그 외 모든 물건은 "생활용품".
중요: estimatedQuantity는 반드시 숫자(integer)로 반환해. 문자열이나 "1개" 같은 형태 금지. 알 수 없으면 1을 반환해.

영수증 텍스트:
${ocrText}`;

Deno.serve(async (req: Request) => {
  // JWT 유효성 검증
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
  let mode: string;
  let imageBase64: string | undefined;
  let mimeType: string;
  let ocrText: string | undefined;
  try {
    const body = await req.json();
    mode = body.mode ?? "vision";
    imageBase64 = body.imageBase64;
    mimeType = body.mimeType ?? "image/jpeg";
    ocrText = body.ocrText;

    if (mode === "vision" && !imageBase64) throw new Error("missing imageBase64");
    if (mode === "receipt" && !ocrText) throw new Error("missing ocrText");
  } catch {
    return new Response(JSON.stringify({ error: "invalid_request" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 프롬프트 및 메시지 구성
  const messages =
    mode === "receipt"
      ? [{ role: "user", content: RECEIPT_PROMPT(ocrText!) }]
      : [
          {
            role: "user",
            content: [
              { type: "text", text: VISION_PROMPT },
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${imageBase64}` },
              },
            ],
          },
        ];

  const gptRes = await fetch(OPENAI_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages,
      max_tokens: 1000,
    }),
  });

  if (!gptRes.ok) {
    const errBody = await gptRes.json().catch(() => ({}));
    return new Response(JSON.stringify({ error: "gpt_api_error", detail: errBody }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const gptData = await gptRes.json();
  const text = gptData?.choices?.[0]?.message?.content ?? "[]";

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
