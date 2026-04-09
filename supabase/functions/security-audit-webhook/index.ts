import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import postgres from 'npm:postgres@3.4.5';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

type TriggerPayload = {
  type?: string;
  table?: string;
  schema?: string;
  record?: Record<string, unknown> | null;
  old_record?: Record<string, unknown> | null;
  triggered_at?: string;
};

function getEnvOrThrow(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function deriveRecordId(payload: TriggerPayload): string | null {
  const record = payload.record ?? payload.old_record ?? null;
  if (!record) return null;

  const candidateKeys = ['id', 'usuario_id', 'proyecto', 'usuario', 'drive_admin_google_email'];
  for (const key of candidateKeys) {
    const value = record[key];
    if (value != null && String(value).trim().length > 0) {
      return String(value);
    }
  }

  return null;
}

function deriveActorHint(payload: TriggerPayload): string | null {
  const record = payload.record ?? {};
  const oldRecord = payload.old_record ?? {};

  const candidateKeys = [
    'usuario',
    'usuario_logueado',
    'drive_admin_google_email',
    'email',
    'id',
  ];

  for (const source of [record, oldRecord]) {
    for (const key of candidateKeys) {
      const value = source[key];
      if (value != null && String(value).trim().length > 0) {
        return String(value);
      }
    }
  }

  return null;
}

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== 'POST') {
    return errorResponse('Método no permitido', 405);
  }

  try {
    const expectedSecret = getEnvOrThrow('SECURITY_WEBHOOK_SECRET');
    const incomingSecret = req.headers.get('x-security-webhook-secret')?.trim();

    if (!incomingSecret || incomingSecret !== expectedSecret) {
      return errorResponse('No autorizado', 401);
    }

    const payload = (await req.json()) as TriggerPayload;
    if (!payload.type || !payload.table || !payload.schema) {
      return errorResponse('Payload inválido', 400);
    }
    const payloadJson = JSON.stringify(payload);

    const sql = postgres(getEnvOrThrow('SUPABASE_DB_URL'), {
      prepare: false,
      max: 1,
      idle_timeout: 5,
      connect_timeout: 10,
      ssl: 'require',
    });

    try {
      await sql`
        insert into security.audit_events (
          source,
          schema_name,
          table_name,
          operation,
          record_id,
          actor_hint,
          request_id,
          payload
        )
        values (
          'db_webhook',
          ${payload.schema},
          ${payload.table},
          ${payload.type},
          ${deriveRecordId(payload)},
          ${deriveActorHint(payload)},
          ${req.headers.get('x-supabase-webhook-id')},
          ${payloadJson}::jsonb
        )
      `;
    } finally {
      await sql.end();
    }

    return jsonResponse({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
