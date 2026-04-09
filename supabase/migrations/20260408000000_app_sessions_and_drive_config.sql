-- ─────────────────────────────────────────────────────
-- Migration: app_sessions + Drive admin columns
-- ─────────────────────────────────────────────────────

-- 1. Tabla de sesiones propias de la app (sin depender de Supabase Auth)
CREATE TABLE IF NOT EXISTS public.app_sessions (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  token_hash    TEXT        NOT NULL UNIQUE,
  usuario_id    BIGINT      NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  usuario       TEXT        NOT NULL,
  rol           TEXT        NOT NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  revoked_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_sessions_token   ON public.app_sessions(token_hash);
CREATE INDEX IF NOT EXISTS idx_app_sessions_expires ON public.app_sessions(expires_at);

-- Solo service_role puede acceder (Edge Functions)
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;
-- No policies = solo service_role puede operar (RLS bloquea anon y authenticated JWT normales)

-- 2. Columnas Drive del admin en configuracion_global
ALTER TABLE public.configuracion_global
  ADD COLUMN IF NOT EXISTS drive_admin_google_email   TEXT,
  ADD COLUMN IF NOT EXISTS drive_admin_refresh_token_enc TEXT,
  ADD COLUMN IF NOT EXISTS drive_admin_linked_at       TIMESTAMPTZ;
