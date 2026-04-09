import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { validateAppSession } from '../_shared/session.ts';

type CampaignType = 'modal' | 'banner' | 'tooltip' | 'badge';
type CampaignAction = 'seen' | 'dismissed' | 'completed' | 'clicked';

interface CampaignRow {
  id: number;
  type: CampaignType;
  title: string;
  body: string;
  cta_label: string | null;
  cta_route: string | null;
  target_roles: string[] | null;
  target_screen: string | null;
  target_key: string | null;
  badge_count: number | null;
  starts_at: string | null;
  ends_at: string | null;
  priority: number;
  step_order: number;
  min_app_version: string | null;
  max_app_version: string | null;
  is_active: boolean;
}

interface CampaignEventRow {
  campaign_id: number;
  action: CampaignAction;
  created_at: string;
}

const TERMINAL_ACTIONS = new Set<CampaignAction>([
  'seen',
  'dismissed',
  'completed',
]);

function normalizeString(value: string | null | undefined): string {
  return (value ?? '').trim().toLowerCase();
}

function normalizeRoles(value: string[] | null | undefined): string[] {
  return (value ?? [])
    .map((role) => role.trim().toUpperCase())
    .filter((role) => role.length > 0);
}

function parseVersionParts(version: string | null | undefined): number[] {
  const cleaned = (version ?? '').trim();
  if (!cleaned) return [];
  return cleaned
    .split(/[^0-9]+/)
    .filter(Boolean)
    .map((part) => Number.parseInt(part, 10))
    .filter((part) => Number.isFinite(part));
}

function compareVersions(a: string | null | undefined, b: string | null | undefined): number {
  const aParts = parseVersionParts(a);
  const bParts = parseVersionParts(b);
  const maxLength = Math.max(aParts.length, bParts.length);

  for (let i = 0; i < maxLength; i += 1) {
    const left = aParts[i] ?? 0;
    const right = bParts[i] ?? 0;
    if (left > right) return 1;
    if (left < right) return -1;
  }

  return 0;
}

function matchesVersion(
  currentVersion: string,
  minVersion: string | null,
  maxVersion: string | null,
): boolean {
  if (minVersion && compareVersions(currentVersion, minVersion) < 0) return false;
  if (maxVersion && compareVersions(currentVersion, maxVersion) > 0) return false;
  return true;
}

function matchesRole(sessionRole: string, targetRoles: string[] | null): boolean {
  const normalizedRoles = normalizeRoles(targetRoles);
  if (normalizedRoles.length === 0) return true;
  return normalizedRoles.includes(sessionRole.trim().toUpperCase());
}

function matchesScreen(screen: string, targetScreen: string | null): boolean {
  const normalizedTarget = normalizeString(targetScreen);
  if (!normalizedTarget || normalizedTarget === 'all' || normalizedTarget === '*') {
    return true;
  }
  return normalizedTarget === normalizeString(screen);
}

function isWithinActiveWindow(now: Date, startsAt: string | null, endsAt: string | null): boolean {
  if (startsAt) {
    const starts = new Date(startsAt);
    if (!Number.isNaN(starts.getTime()) && now < starts) return false;
  }

  if (endsAt) {
    const ends = new Date(endsAt);
    if (!Number.isNaN(ends.getTime()) && now > ends) return false;
  }

  return true;
}

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

    const { screen, appVersion } = await req.json();
    const normalizedScreen = (screen as string | undefined)?.trim().toLowerCase();
    const normalizedVersion = (appVersion as string | undefined)?.trim() ?? '';

    if (!normalizedScreen) {
      return errorResponse('Falta screen', 400);
    }

    const { data: campaigns, error: campaignsError } = await supabaseAdmin
      .from('app_campaigns')
      .select(`
        id,
        type,
        title,
        body,
        cta_label,
        cta_route,
        target_roles,
        target_screen,
        target_key,
        badge_count,
        starts_at,
        ends_at,
        priority,
        step_order,
        min_app_version,
        max_app_version,
        is_active
      `)
      .eq('is_active', true)
      .order('priority', { ascending: false })
      .order('step_order', { ascending: true })
      .order('id', { ascending: true });

    if (campaignsError) return errorResponse('Error leyendo campañas', 500);

    const now = new Date();
    const filteredCampaigns = ((campaigns ?? []) as CampaignRow[]).filter((campaign) => {
      return (
        campaign.is_active &&
        matchesScreen(normalizedScreen, campaign.target_screen) &&
        matchesRole(session.rol, campaign.target_roles) &&
        isWithinActiveWindow(now, campaign.starts_at, campaign.ends_at) &&
        matchesVersion(normalizedVersion, campaign.min_app_version, campaign.max_app_version)
      );
    });

    if (filteredCampaigns.length === 0) {
      return jsonResponse({ ok: true, campaigns: [] });
    }

    const campaignIds = filteredCampaigns.map((campaign) => campaign.id);
    const { data: events, error: eventsError } = await supabaseAdmin
      .from('app_campaign_events')
      .select('campaign_id, action, created_at')
      .eq('usuario_id', session.usuarioId)
      .in('campaign_id', campaignIds)
      .order('created_at', { ascending: false });

    if (eventsError) return errorResponse('Error leyendo eventos de campañas', 500);

    const latestActions = new Map<number, CampaignAction>();
    for (const event of (events ?? []) as CampaignEventRow[]) {
      if (!latestActions.has(event.campaign_id)) {
        latestActions.set(event.campaign_id, event.action);
      }
    }

    const visibleCampaigns = filteredCampaigns
      .filter((campaign) => {
        const latestAction = latestActions.get(campaign.id);
        if (!latestAction) return true;
        return !TERMINAL_ACTIONS.has(latestAction);
      })
      .map((campaign) => ({
        id: campaign.id,
        type: campaign.type,
        title: campaign.title,
        body: campaign.body,
        ctaLabel: campaign.cta_label,
        ctaRoute: campaign.cta_route,
        targetScreen: campaign.target_screen,
        targetKey: campaign.target_key,
        badgeCount: campaign.badge_count,
        priority: campaign.priority,
        stepOrder: campaign.step_order,
        startsAt: campaign.starts_at,
        endsAt: campaign.ends_at,
      }));

    return jsonResponse({ ok: true, campaigns: visibleCampaigns });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
