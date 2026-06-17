import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// notify-message — invoked by a DB trigger (pg_net) after each message insert.
// Looks up the recipient's device tokens and sends an APNs alert push.
//
// Auth: a shared-secret header (`x-push-secret`); verify_jwt is DISABLED because
// the caller is the database (pg_net), not an end user.
//
// Required Edge secrets (Dashboard → Edge Functions → Manage secrets):
//   PUSH_FUNCTION_SECRET  — same value stored in Vault `push_function_secret`
//   APNS_KEY_ID           — the APNs Auth Key (.p8) Key ID
//   APNS_TEAM_ID          — Apple Team ID (T82VDBUCDV)
//   APNS_BUNDLE_ID        — com.stickermatch.app
//   APNS_PRIVATE_KEY      — full contents of the AuthKey_XXXX.p8 (PEM)
//   APNS_ENV              — "sandbox" (dev builds) or "production" (TestFlight/App Store)
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected automatically.

const PUSH_SECRET  = Deno.env.get("PUSH_FUNCTION_SECRET") ?? "";
const APNS_KEY_ID  = Deno.env.get("APNS_KEY_ID") ?? "";
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID") ?? "";
const APNS_BUNDLE  = Deno.env.get("APNS_BUNDLE_ID") ?? "";
const APNS_KEY_P8  = Deno.env.get("APNS_PRIVATE_KEY") ?? "";
const APNS_ENV     = (Deno.env.get("APNS_ENV") ?? "sandbox").toLowerCase();
const APNS_HOST    = APNS_ENV === "production" ? "api.push.apple.com" : "api.sandbox.push.apple.com";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function b64url(input: ArrayBuffer | Uint8Array | string): string {
  let bytes: Uint8Array;
  if (typeof input === "string") bytes = new TextEncoder().encode(input);
  else if (input instanceof Uint8Array) bytes = input;
  else bytes = new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let cachedKey: CryptoKey | null = null;
async function importKey(): Promise<CryptoKey> {
  if (cachedKey) return cachedKey;
  const pem = APNS_KEY_P8
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  cachedKey = await crypto.subtle.importKey(
    "pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"],
  );
  return cachedKey;
}

// APNs provider JWT (ES256). Reusable up to ~1h; refresh every 50 min.
let cachedJwt = "";
let cachedJwtAt = 0;
async function providerToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwtAt < 50 * 60) return cachedJwt;
  const header  = b64url(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }));
  const payload = b64url(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }));
  const signingInput = `${header}.${payload}`;
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    await importKey(),
    new TextEncoder().encode(signingInput),
  );
  cachedJwt = `${signingInput}.${b64url(sig)}`;
  cachedJwtAt = now;
  return cachedJwt;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }
  if (!PUSH_SECRET || req.headers.get("x-push-secret") !== PUSH_SECRET) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }
  if (!APNS_KEY_P8 || !APNS_KEY_ID || !APNS_TEAM_ID || !APNS_BUNDLE) {
    console.error("APNs not configured — set the APNS_* Edge secrets.");
    return new Response(JSON.stringify({ ok: true, skipped: "unconfigured" }), { status: 200 });
  }

  let payload: { conversation_id?: string; sender_id?: string; body?: string };
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Bad JSON" }), { status: 400 });
  }
  const { conversation_id, sender_id, body } = payload;
  if (!conversation_id || !sender_id) {
    return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 });
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);

  // Recipient = the conversation participant who is NOT the sender.
  const { data: convo } = await admin
    .from("conversations")
    .select("user_a, user_b, nickname_a, nickname_b")
    .eq("id", conversation_id)
    .single();
  if (!convo) return new Response(JSON.stringify({ ok: true, skipped: "no convo" }), { status: 200 });

  const recipient = sender_id === convo.user_a ? convo.user_b : convo.user_a;
  const senderName = (sender_id === convo.user_a ? convo.nickname_a : convo.nickname_b) || "New message";

  const { data: tokens } = await admin
    .from("device_tokens")
    .select("token")
    .eq("user_id", recipient);
  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ ok: true, sent: 0 }), { status: 200 });
  }

  const jwt = await providerToken();
  const apsPayload = JSON.stringify({
    aps: { alert: { title: senderName, body: (body ?? "").slice(0, 150) }, sound: "default" },
    conversation_id,
  });

  let sent = 0;
  const stale: string[] = [];
  await Promise.all(tokens.map(async ({ token }: { token: string }) => {
    const res = await fetch(`https://${APNS_HOST}/3/device/${token}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": APNS_BUNDLE,
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      body: apsPayload,
    });
    if (res.status === 200) { sent++; return; }
    const text = await res.text();
    // 410 Unregistered or 400 BadDeviceToken → token is dead; clean it up.
    if (res.status === 410 || text.includes("BadDeviceToken")) stale.push(token);
    else console.error(`APNs ${res.status} for ${token.slice(0, 8)}…: ${text}`);
  }));

  if (stale.length) {
    await admin.from("device_tokens").delete().in("token", stale);
  }

  return new Response(JSON.stringify({ ok: true, sent, removed: stale.length }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
