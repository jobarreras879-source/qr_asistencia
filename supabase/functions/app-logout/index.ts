import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { validateAppSession } from '../_shared/session.ts';

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

    const { error } = await supabaseAdmin
      .from('app_sessions')
      .update({ revoked_at: new Date().toISOString() })
      .eq('id', session.id);

    if (error) return errorResponse('Error cerrando sesión', 500);

    return jsonResponse({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
