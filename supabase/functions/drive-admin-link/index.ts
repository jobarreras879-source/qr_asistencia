import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { ensureConfigSchema } from '../_shared/config_schema.ts';
import { validateAppSession, requireAdmin } from '../_shared/session.ts';
import { exchangeAuthCode, encryptToken } from '../_shared/drive_google.ts';

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

    const { serverAuthCode } = await req.json();
    if (!serverAuthCode) return errorResponse('Falta serverAuthCode', 400);

    const clientId = Deno.env.get('GOOGLE_CLIENT_ID')!;
    const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET')!;
    const encryptionKey = Deno.env.get('DRIVE_ENCRYPTION_KEY')!;

    if (!clientId || !clientSecret || !encryptionKey) {
      return errorResponse('Configuración de servidor incompleta (secrets)', 500);
    }

    // Exchange auth code → refresh token + email
    const linked = await exchangeAuthCode(serverAuthCode, clientId, clientSecret);

    // Encrypt the refresh token before storing
    const encryptedToken = await encryptToken(linked.refresh_token, encryptionKey);

    // Upsert into configuracion_global (row 1)
    const { data: existing } = await supabaseAdmin
      .from('configuracion_global')
      .select('id')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    const drivePayload = {
      drive_admin_google_email: linked.email,
      drive_admin_refresh_token_enc: encryptedToken,
      drive_admin_linked_at: new Date().toISOString(),
    };

    let dbError;
    if (existing?.id) {
      const { error } = await supabaseAdmin
        .from('configuracion_global')
        .update(drivePayload)
        .eq('id', existing.id);
      dbError = error;
    } else {
      const { error } = await supabaseAdmin
        .from('configuracion_global')
        .insert(drivePayload);
      dbError = error;
    }

    if (dbError) return errorResponse(`Error guardando configuración: ${dbError.message}`, 500);

    // Read current folder info to return complete status
    const { data: config } = await supabaseAdmin
      .from('configuracion_global')
      .select('drive_folder_id, drive_folder_name')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    return jsonResponse({
      ok: true,
      linked: true,
      linkedEmail: linked.email,
      folderId: config?.drive_folder_id ?? null,
      folderName: config?.drive_folder_name ?? null,
    });
  } catch (err: unknown) {
    let message = err instanceof Error ? err.message : 'Error desconocido';
    if (message.includes('invalid_grant')) {
      message =
        'OAuth exchange failed: invalid_grant. Revisa que GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET en Supabase pertenezcan al mismo cliente web usado por la app.';
    }
    return errorResponse(message, 500);
  }
});
