import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { validateAppSession } from '../_shared/session.ts';

const ALLOWED_ACTIONS = new Set(['seen', 'dismissed', 'completed', 'clicked']);

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== 'POST') {
    return errorResponse('Método no permitido', 405);
  }

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

    const { campaignId, action } = await req.json();
    const normalizedAction = (action as string | undefined)?.trim().toLowerCase();
    const normalizedCampaignId = Number.parseInt(String(campaignId ?? ''), 10);

    if (!Number.isFinite(normalizedCampaignId)) {
      return errorResponse('campaignId inválido', 400);
    }
    if (!normalizedAction || !ALLOWED_ACTIONS.has(normalizedAction)) {
      return errorResponse('action inválida', 400);
    }

    const { data: campaign, error: campaignError } = await supabaseAdmin
      .from('app_campaigns')
      .select('id')
      .eq('id', normalizedCampaignId)
      .maybeSingle();

    if (campaignError) return errorResponse('Error validando campaña', 500);
    if (!campaign) return errorResponse('Campaña no encontrada', 404);

    const { error: insertError } = await supabaseAdmin
      .from('app_campaign_events')
      .insert({
        campaign_id: normalizedCampaignId,
        usuario_id: session.usuarioId,
        action: normalizedAction,
      });

    if (insertError) return errorResponse('Error registrando evento', 500);

    return jsonResponse({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
