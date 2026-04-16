import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID")!;

// 피보나치 대기 일수 배열 (인덱스 = send_count)
const FIBONACCI_DAYS = [1, 2, 3, 5, 8];

// ─── 한국어 조사 헬퍼 ────────────────────────────────────────────────
function hasBatchim(word: string): boolean {
  const code = word.charCodeAt(word.length - 1);
  if (code < 0xac00 || code > 0xd7a3) return false;
  return (code - 0xac00) % 28 !== 0;
}

// 이/가
function ga(word: string): string {
  return hasBatchim(word) ? "이" : "가";
}
const MAX_SEND_COUNT = FIBONACCI_DAYS.length;

type NotifType = "expiry_evening" | "expiry_noon" | "low_stock";

// ─── APNs JWT 생성 ─────────────────────────────────────────────────
async function generateApnsJwt(): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const payload = { iss: APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  const pemKey = APNS_PRIVATE_KEY.replace(/\\n/g, "\n");
  const keyData = pemKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  return `${signingInput}.${sig}`;
}

// ─── APNs 발송 ──────────────────────────────────────────────────────
async function sendApns(
  token: string,
  title: string,
  body: string,
  jwt: string
): Promise<"success" | "failed" | "invalid_token"> {
  // 개발 빌드(Xcode)는 샌드박스 환경 사용
  const apnsHost = "api.sandbox.push.apple.com";
  const url = `https://${apnsHost}/3/device/${token}`;
  const payload = JSON.stringify({
    aps: { alert: { title, body }, sound: "default" },
  });

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": APNS_BUNDLE_ID,
        "content-type": "application/json",
      },
      body: payload,
    });

    if (res.status === 200) return "success";
    if (res.status === 410) return "invalid_token";
    return "failed";
  } catch (e) {
    console.error("APNs fetch error:", e);
    return "failed";
  }
}

// ─── 오늘 이미 발송됐는지 확인 ──────────────────────────────────────
async function alreadySentToday(
  supabase: ReturnType<typeof createClient>,
  itemId: string,
  type: NotifType
): Promise<boolean> {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const { data } = await supabase
    .from("notification_logs")
    .select("id")
    .eq("item_id", itemId)
    .eq("type", type)
    .eq("apns_status", "success")
    .gte("sent_at", todayStart.toISOString())
    .limit(1);

  return (data?.length ?? 0) > 0;
}

// ─── 그룹 알림 발송 + 아이템별 로그 기록 ───────────────────────────
async function sendGroupedAndLog(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  items: { id: string }[],
  type: NotifType,
  title: string,
  body: string,
  jwt: string
) {
  const { data: tokens } = await supabase
    .from("user_device_tokens")
    .select("device_token")
    .eq("user_id", userId);

  if (!tokens || tokens.length === 0) return;

  let apnsStatus: "success" | "failed" | "invalid_token" = "failed";
  for (const { device_token } of tokens) {
    apnsStatus = await sendApns(device_token, title, body, jwt);

    if (apnsStatus === "invalid_token") {
      await supabase
        .from("user_device_tokens")
        .delete()
        .eq("device_token", device_token);
    }
  }

  // 아이템마다 개별 로그 → alreadySentToday 중복 방지에 활용
  for (const item of items) {
    await supabase.from("notification_logs").insert({
      user_id: userId,
      item_id: item.id,
      type,
      apns_status: apnsStatus,
    });
  }
}

// ─── 알림 발송 + 로그 기록 (단건) ──────────────────────────────────
async function sendAndLog(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  itemId: string,
  type: NotifType,
  title: string,
  body: string,
  jwt: string
) {
  await sendGroupedAndLog(supabase, userId, [{ id: itemId }], type, title, body, jwt);
}

// ─── 유통기한 알림 처리 ─────────────────────────────────────────────
async function handleExpiryNotification(
  supabase: ReturnType<typeof createClient>,
  type: "expiry_evening" | "expiry_noon",
  jwt: string
) {
  // KST 기준 날짜 계산 (UTC+9)
  const nowKST = new Date(Date.now() + 9 * 60 * 60 * 1000);
  if (type === "expiry_evening") {
    nowKST.setUTCDate(nowKST.getUTCDate() + 1); // 내일 KST
  }
  const dateStr = nowKST.toISOString().split("T")[0]; // KST 기준 YYYY-MM-DD

  // KST 00:00 ~ 23:59:59 를 UTC ISO로 변환
  const dayStartUTC = new Date(`${dateStr}T00:00:00+09:00`).toISOString();
  const dayEndUTC = new Date(`${dateStr}T23:59:59.999+09:00`).toISOString();

  const { data: items } = await supabase
    .from("items")
    .select("id, user_id, name")
    .gte("expiry_date", dayStartUTC)
    .lt("expiry_date", dayEndUTC)
    .is("deleted_at", null)
    .order("expiry_date", { ascending: true });

  if (!items || items.length === 0) return;

  // 미발송 아이템만 필터링
  const pendingItems: typeof items = [];
  for (const item of items) {
    if (!(await alreadySentToday(supabase, item.id, type))) {
      pendingItems.push(item);
    }
  }
  if (pendingItems.length === 0) return;

  // 유저별 그룹화
  const byUser = new Map<string, typeof items>();
  for (const item of pendingItems) {
    if (!byUser.has(item.user_id)) byUser.set(item.user_id, []);
    byUser.get(item.user_id)!.push(item);
  }

  const timeLabel = type === "expiry_evening" ? "내일" : "오늘";

  for (const [userId, userItems] of byUser) {
    let body: string;
    const last = userItems[userItems.length - 1].name;
    if (userItems.length === 1) {
      body = `${userItems[0].name}${ga(userItems[0].name)} ${timeLabel} 유통기한이 만료돼요!`;
    } else if (userItems.length === 2) {
      body = `${userItems[0].name}, ${userItems[1].name}${ga(last)} ${timeLabel} 유통기한이 만료돼요!`;
    } else {
      const extra = userItems.length - 2;
      body = `${userItems[0].name}, ${userItems[1].name} 외 ${extra}개가 ${timeLabel} 만료돼요!`;
    }

    await sendGroupedAndLog(supabase, userId, userItems, type, "유통기한 알림", body, jwt);
  }
}

// ─── 재고 부족 피보나치 알림 처리 ───────────────────────────────────
async function handleLowStockNotification(
  supabase: ReturnType<typeof createClient>,
  jwt: string
) {
  const { data: allCandidates } = await supabase
    .from("items")
    .select("id, user_id, name, quantity, low_stock_threshold")
    .eq("is_low_stock_notification_enabled", true)
    .is("deleted_at", null);

  const lowStockItems = (allCandidates ?? []).filter(
    (item) => item.quantity <= item.low_stock_threshold
  );

  const lowStockItemIds = new Set(lowStockItems.map((i) => i.id));

  const { data: allStates } = await supabase
    .from("low_stock_alert_states")
    .select("id, item_id");

  // 회복된 아이템 추적 상태 삭제
  const recoveredIds = (allStates ?? [])
    .filter((s) => !lowStockItemIds.has(s.item_id))
    .map((s) => s.id);

  if (recoveredIds.length > 0) {
    await supabase
      .from("low_stock_alert_states")
      .delete()
      .in("id", recoveredIds);
  }

  // 신규 진입 아이템 INSERT
  const existingItemIds = new Set((allStates ?? []).map((s) => s.item_id));

  for (const item of lowStockItems) {
    if (!existingItemIds.has(item.id)) {
      await supabase.from("low_stock_alert_states").insert({
        user_id: item.user_id,
        item_id: item.id,
      });
    }
  }

  const { data: states } = await supabase
    .from("low_stock_alert_states")
    .select("*");

  const now = new Date();

  for (const state of states ?? []) {
    if (state.send_count >= MAX_SEND_COUNT) continue;

    const waitDays = FIBONACCI_DAYS[state.send_count];
    const referenceDate = state.last_sent_at
      ? new Date(state.last_sent_at)
      : new Date(state.first_low_stock_at);

    const daysSinceReference =
      (now.getTime() - referenceDate.getTime()) / (1000 * 60 * 60 * 24);

    if (daysSinceReference < waitDays) continue;

    const item = lowStockItems.find((i) => i.id === state.item_id);
    if (!item) continue;

    await sendAndLog(
      supabase,
      state.user_id,
      state.item_id,
      "low_stock",
      "재고 부족 알림",
      `${item.name} 재고가 ${item.quantity}개 남았어요!`,
      jwt
    );

    await supabase
      .from("low_stock_alert_states")
      .update({ send_count: state.send_count + 1, last_sent_at: now.toISOString() })
      .eq("id", state.id);
  }
}

// ─── 메인 핸들러 ────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // TODO: Sign in with Apple 구현 후 JWT 검증으로 교체 예정
  let body: { type?: NotifType };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { type } = body;
  if (!type || !["expiry_evening", "expiry_noon", "low_stock"].includes(type)) {
    return new Response(JSON.stringify({ error: "Invalid type" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let jwt: string;
  try {
    jwt = await generateApnsJwt();
  } catch (err) {
    console.error("APNs JWT generation failed:", err);
    return new Response(JSON.stringify({ error: "APNs JWT error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    if (type === "expiry_evening" || type === "expiry_noon") {
      await handleExpiryNotification(supabase, type, jwt);
    } else {
      await handleLowStockNotification(supabase, jwt);
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("send-notifications error:", err);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
