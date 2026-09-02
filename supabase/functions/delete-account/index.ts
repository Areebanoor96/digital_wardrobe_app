// Permanent account deletion Edge Function.
//
// Authorizes the request via the caller's JWT, then with the service-role key
// (server-side only):
//
//   1. Removes the caller's user-owned Storage objects (garment photos in the
//      `garments` bucket and family avatars in the `profile_avatars` bucket),
//      because Storage is not a relational table and is NOT cleaned up by a
//      database cascade.
//   2. Deletes the Supabase Auth user. All user-owned database rows reference
//      `profiles(id)` -> `auth.users(id) ON DELETE CASCADE` (or
//      `growth_measurements` directly on `auth.users`), so the cascade removes
//      every user-owned table row.
//
// The service-role key never leaves this function and never reaches the client.

import { createClient } from "npm:@supabase/supabase-js@2";

const GARMENT_BUCKET = "garments";
const AVATAR_BUCKET = "profile_avatars";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// List a folder recursively (depth-first) and remove every object under it.
async function removeAllObjects(
  bucket: ReturnType<ReturnType<typeof createClient>["storage"]["from"]>,
  userId: string,
): Promise<{ removed: number }> {
  let removed = 0;

  async function walk(prefix: string): Promise<void> {
    const { data: entries, error } = await bucket.list(prefix, {
      limit: 200,
      offset: 0,
    });

    if (error) {
      // A missing bucket/prefix is not fatal; continue with other buckets.
      return;
    }

    for (const entry of entries ?? []) {
      const path = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (entry.id) {
        // It is a file object.
        const { error: removeError } = await bucket.remove([path]);
        if (!removeError) {
          removed += 1;
        }
      } else {
        // It is a folder.
        await walk(path);
      }
    }
  }

  await walk(userId);
  return { removed };
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

  const userId = user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 1. Remove user-owned Storage objects.
  let removedGarmentObjects = 0;
  let removedAvatarObjects = 0;
  try {
    ({ removed: removedGarmentObjects } = await removeAllObjects(
      admin.storage.from(GARMENT_BUCKET),
      userId,
    ));
  } catch (_) {
    // Best effort; continue to delete the auth user.
  }

  try {
    ({ removed: removedAvatarObjects } = await removeAllObjects(
      admin.storage.from(AVATAR_BUCKET),
      userId,
    ));
  } catch (_) {
    // Best effort; continue to delete the auth user.
  }

  // 2. Delete the Auth user. Database rows cascade from profiles / auth.users.
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);

  if (deleteError) {
    return json({ error: "Unable to delete the account." }, 500);
  }

  return json({
    deleted: true,
    removedGarmentObjects,
    removedAvatarObjects,
  });
});
