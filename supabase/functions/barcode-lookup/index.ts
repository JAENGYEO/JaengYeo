import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FOOD_SAFETY_API_KEY = Deno.env.get("FOOD_SAFETY_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CACHE_TTL_DAYS = 30;

serve(async (req: Request) => {
  // JWT 검증
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "missing_authorization" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 요청 파싱
  let barcode: string;
  try {
    const body = await req.json();
    barcode = body.barcode;
    if (!barcode) throw new Error("missing barcode");
  } catch {
    return new Response(JSON.stringify({ error: "invalid_request" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // 캐시 조회
  const cacheExpiry = new Date();
  cacheExpiry.setDate(cacheExpiry.getDate() - CACHE_TTL_DAYS);

  const { data: cached } = await supabase
    .from("barcode_cache")
    .select("*")
    .eq("barcode", barcode)
    .gte("cached_at", cacheExpiry.toISOString())
    .maybeSingle();

  if (cached) {
    // 캐시 HIT: hit_count 증가 후 반환
    await supabase
      .from("barcode_cache")
      .update({ hit_count: (cached.hit_count ?? 1) + 1 })
      .eq("barcode", barcode);

    return new Response(
      JSON.stringify({
        productName: cached.product_name,
        manufacturer: cached.manufacturer,
        barcode: cached.barcode,
        fromCache: true,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  // 캐시 MISS: 식품안전나라 API 호출
  const apiUrl = `https://openapi.foodsafetykorea.go.kr/api/${FOOD_SAFETY_API_KEY}/C005/json/1/1/BAR_CD=${barcode}`;
  const apiRes = await fetch(apiUrl);
  const apiData = await apiRes.json();

  const row = apiData?.C005?.row?.[0];
  if (!row) {
    return new Response(JSON.stringify({ error: "product_not_found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  const productName = row.PRDLST_NM ?? null;
  const manufacturer = row.BSSH_NM ?? null;

  // 캐시 저장
  await supabase.from("barcode_cache").upsert(
    {
      barcode,
      product_name: productName,
      manufacturer,
      raw_response: row,
      cached_at: new Date().toISOString(),
      hit_count: 1,
    },
    { onConflict: "barcode" }
  );

  return new Response(
    JSON.stringify({
      productName,
      manufacturer,
      barcode,
      fromCache: false,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
