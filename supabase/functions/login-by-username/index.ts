import { createClient } from "npm:@supabase/supabase-js@^2";
import { corsHeaders } from "npm:@supabase/supabase-js@^2/cors";

type LoginResponse = {
  ok: boolean;
  code?: "invalid_credentials" | "pending" | "rejected" | "suspended" | "deleted" | "server_error";
  error?: string;
  access_token?: string;
  refresh_token?: string;
  expires_in?: number;
  token_type?: string;
  user?: { id: string };
};

const json = (body: LoginResponse, status = 200) =>
  Response.json(body, { status, headers: corsHeaders });

Deno.serve(async (req: Request) => {
  // Cette fonction est appelée avant authentification : le preflight doit toujours passer.
  if (req.method === "OPTIONS") {
    return Response.json({ ok: true }, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, code: "server_error", error: "Méthode non autorisée." }, 405);
  }

  try {
    const payload = await req.json().catch(() => ({}));
    const username = String(payload?.username ?? "").trim();
    const password = String(payload?.password ?? "");

    if (!username || !password) {
      return json({ ok: false, code: "invalid_credentials", error: "Pseudo ou mot de passe incorrect." });
    }

    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !anonKey || !serviceKey) {
      throw new Error("Configuration Supabase incomplète.");
    }

    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // 1) Retrouver l'identité technique liée au pseudo.
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id,status")
      .ilike("username", username)
      .maybeSingle();

    if (profileError || !profile) {
      return json({ ok: false, code: "invalid_credentials", error: "Pseudo ou mot de passe incorrect." });
    }

    const { data: userData, error: userError } = await admin.auth.admin.getUserById(profile.id);
    const email = userData?.user?.email;
    if (userError || !email) {
      return json({ ok: false, code: "invalid_credentials", error: "Pseudo ou mot de passe incorrect." });
    }

    // 2) Vérifier D'ABORD le mot de passe. On ne révèle jamais le statut d'un compte
    //    à quelqu'un qui ne connaît pas ses identifiants.
    const publicClient = createClient(url, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await publicClient.auth.signInWithPassword({ email, password });
    if (error || !data.session || !data.user) {
      return json({ ok: false, code: "invalid_credentials", error: "Pseudo ou mot de passe incorrect." });
    }

    // 3) L'Auth Supabase est valide, mais c'est LE NID qui décide si le joueur entre.
    switch (profile.status) {
      case "pending":
        return json({ ok: false, code: "pending", error: "Ta demande est encore en attente d'autorisation du Hibou." });
      case "rejected":
        return json({ ok: false, code: "rejected", error: "Ta demande d'inscription n'a pas été acceptée." });
      case "suspended":
        return json({ ok: false, code: "suspended", error: "Ce compte est actuellement suspendu." });
      case "deleted":
        return json({ ok: false, code: "deleted", error: "Ce compte n'est plus actif." });
      case "active":
        break;
      default:
        return json({ ok: false, code: "server_error", error: "Statut de compte inconnu." });
    }

    return json({
      ok: true,
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      token_type: data.session.token_type,
      user: { id: data.user.id },
    });
  } catch (error) {
    console.error("login-by-username", error);
    return json({ ok: false, code: "server_error", error: "Connexion temporairement indisponible." }, 500);
  }
});
