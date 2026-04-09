import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

function getSessionTtlDays(): number {
  const raw = Number.parseInt(Deno.env.get('APP_SESSION_TTL_DAYS') ?? '30', 10);
  if (!Number.isFinite(raw)) return 30;
  return Math.min(Math.max(raw, 1), 90);
}

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { usuario, password } = await req.json();

    if (!usuario || !password) {
      return errorResponse('Faltan campos: usuario, password', 400);
    }

    const normalizedUser = (usuario as string).trim().toLowerCase();
    const passwordHash = await sha256Hex(password);

    // Buscar en la tabla usuarios (modelo existente)
    const { data: user, error } = await supabaseAdmin
      .from('usuarios')
      .select('id, usuario, rol, activo')
      .eq('usuario', normalizedUser)
      .eq('password_hash', passwordHash)
      .eq('activo', true)
      .maybeSingle();

    if (error) return errorResponse('Error de base de datos', 500);
    if (!user) return errorResponse('Credenciales inválidas', 401);

    // Generar token aleatorio seguro
    const rawToken = crypto.randomUUID() + crypto.randomUUID();
    const tokenHash = await sha256Hex(rawToken);

    // TTL corto y configurable para reducir el riesgo de sesiones persistentes.
    const ttlDays = getSessionTtlDays();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + ttlDays);

    const { error: insertError } = await supabaseAdmin.from('app_sessions').insert({
      token_hash: tokenHash,
      usuario_id: user.id,
      usuario: user.usuario,
      rol: user.rol,
      expires_at: expiresAt.toISOString(),
    });

    if (insertError) return errorResponse('Error creando sesión', 500);

    return jsonResponse({
      ok: true,
      token: rawToken,
      expiresAt: expiresAt.toISOString(),
      user: {
        id: user.id,
        usuario: user.usuario,
        rol: user.rol,
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
