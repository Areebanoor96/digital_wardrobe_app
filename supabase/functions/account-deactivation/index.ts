// Account status Edge Function (temporary deactivation / reactivation).
//
// Requires the caller's JWT. Uses the service-role key (available only in this
// server-side context) so it can toggle `profiles.deactivated_at` regardless of
// column-level client restrictions. It never returns the service key and only
// ever acts on the authenticated caller's own row.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type Action = "deactivate" | "reactivate";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return json({ error: "Server configuration is incomplete." }, 500);
  }

  // The anonymous client verifies the caller's JWT and resolves their uid.
  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const authHeader =
    req.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ?? "";
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(authHeader);

  if (userError || !user) {
    return json({ error: "Not authenticated." }, 401);
  }

  let body: { action?: Action };
  try {
    body = (await req.json()) as { action?: Action };
  } catch (_) {
    return json({ error: "Request body must be valid JSON." }, 400);
  }

  if (body.action !== "deactivate" && body.action !== "reactivate") {
    return json({ error: "action must be 'deactivate' or 'reactivate'." }, 400);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const deactivatedAt =
    body.action === "deactivate" ? new Date().toISOString() : null;

  const { data, error } = await admin
    .from("profiles")
    .update({ deactivated_at: deactivatedAt })
    .eq("id", user.id)
    .select("deactivated_at")
    .maybeSingle();

  if (error) {
    return json({ error: "Unable to update account status." }, 500);
  }

  return json({
    action: body.action,
    deactivated_at: data?.deactivated_at ?? null,
  });
});
