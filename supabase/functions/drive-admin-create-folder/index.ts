import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { ensureConfigSchema } from '../_shared/config_schema.ts';
import { validateAppSession, requireAdmin } from '../_shared/session.ts';
import { getAccessToken, decryptToken, createDriveFolder } from '../_shared/drive_google.ts';

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    let session;
    try {
      session = await validateAppSession(req, supabaseAdmin);
    } catch (e) {
      return e as Response;
    }
    try {
      requireAdmin(session);
    } catch (e) {
      return e as Response;
    }

    await ensureConfigSchema();

    const { name } = await req.json();
    if (!name || typeof name !== 'string' || !name.trim()) {
      return errorResponse('Falta el nombre de la carpeta', 400);
    }

    const { data: config, error: configError } = await supabaseAdmin
      .from('configuracion_global')
      .select('drive_admin_refresh_token_enc')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    if (configError || !config?.drive_admin_refresh_token_enc) {
      return errorResponse('Drive no vinculado', 400);
    }

    const clientId = Deno.env.get('GOOGLE_CLIENT_ID')!;
    const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET')!;
    const encryptionKey = Deno.env.get('DRIVE_ENCRYPTION_KEY')!;

    const refreshToken = await decryptToken(config.drive_admin_refresh_token_enc, encryptionKey);
    const accessToken = await getAccessToken(refreshToken, clientId, clientSecret);

    const folder = await createDriveFolder(name.trim(), accessToken);

    return jsonResponse({ ok: true, folder });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
