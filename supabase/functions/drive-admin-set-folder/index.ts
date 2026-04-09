import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { ensureConfigSchema } from '../_shared/config_schema.ts';
import { validateAppSession, requireAdmin } from '../_shared/session.ts';

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

    const { folderId, folderName } = await req.json();
    if (!folderId || !folderName) {
      return errorResponse('Faltan campos: folderId, folderName', 400);
    }

    const { data: existing } = await supabaseAdmin
      .from('configuracion_global')
      .select('id')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    let dbError;
    const folderPayload = {
      drive_folder_id: folderId,
      drive_folder_name: folderName,
    };

    if (existing?.id) {
      const { error } = await supabaseAdmin
        .from('configuracion_global')
        .update(folderPayload)
        .eq('id', existing.id);
      dbError = error;
    } else {
      const { error } = await supabaseAdmin
        .from('configuracion_global')
        .insert(folderPayload);
      dbError = error;
    }

    if (dbError) return errorResponse(`Error guardando carpeta: ${dbError.message}`, 500);

    return jsonResponse({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
