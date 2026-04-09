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

    const { data: existing } = await supabaseAdmin
      .from('configuracion_global')
      .select('id')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    if (!existing?.id) {
      return errorResponse('No existe configuración para limpiar', 400);
    }

    const { error } = await supabaseAdmin
      .from('configuracion_global')
      .update({
        drive_admin_google_email: null,
        drive_admin_refresh_token_enc: null,
        drive_admin_linked_at: null,
        drive_folder_id: null,
        drive_folder_name: null,
      })
      .eq('id', existing.id);

    if (error) return errorResponse(`Error desvinculando Drive: ${error.message}`, 500);

    return jsonResponse({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
