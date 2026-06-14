import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Deletes the calling user's account. verify_jwt=true ensures only an
// authenticated request reaches here; we re-derive the user from their JWT and
// delete with the service role. FK cascades (auth.users -> profiles -> ...)
// wipe all of their data.
//
// Deploy: supabase functions deploy delete-account
Deno.serve(async (req: Request) => {
  const cors = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, content-type",
  };
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), { status: 401, headers: cors });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Identify the caller from their JWT.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), { status: 401, headers: cors });
  }

  // Delete with the service role; cascades remove all of the user's data.
  const admin = createClient(supabaseUrl, serviceKey);
  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) {
    return new Response(JSON.stringify({ error: delErr.message }), { status: 500, headers: cors });
  }

  return new Response(JSON.stringify({ success: true }), { status: 200, headers: cors });
});
