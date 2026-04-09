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

    const { data, error } = await supabaseAdmin
      .from('configuracion_global')
      .select('drive_admin_google_email, drive_folder_id, drive_folder_name, drive_admin_linked_at')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    if (error) return errorResponse('Error leyendo configuración', 500);

    const linked = !!data?.drive_admin_google_email;

    return jsonResponse({
      ok: true,
      linked,
      email: data?.drive_admin_google_email ?? null,
      folderId: data?.drive_folder_id ?? null,
      folderName: data?.drive_folder_name ?? null,
      linkedAt: data?.drive_admin_linked_at ?? null,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
