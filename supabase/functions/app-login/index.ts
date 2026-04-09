import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import bcrypt from 'npm:bcryptjs@3.0.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

function isBcryptHash(hash: string): boolean {
  return hash.startsWith('$2a$') || hash.startsWith('$2b$') || hash.startsWith('$2y$');
}

async function verifyPassword(
  password: string,
  storedHash: string,
): Promise<{ ok: boolean; upgradedHash?: string }> {
  if (isBcryptHash(storedHash)) {
    return { ok: await bcrypt.compare(password, storedHash) };
  }

  const legacyHash = await sha256Hex(password);
  if (legacyHash !== storedHash) {
    return { ok: false };
  }

  return {
    ok: true,
    upgradedHash: await bcrypt.hash(password, 10),
  };
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
    // Buscar en la tabla usuarios y validar contra el hash guardado.
    const { data: user, error } = await supabaseAdmin
      .from('usuarios')
      .select('id, usuario, rol, activo, password_hash')
      .eq('usuario', normalizedUser)
      .eq('activo', true)
      .maybeSingle();

    if (error) return errorResponse('Error de base de datos', 500);
    if (!user) return errorResponse('Credenciales inválidas', 401);

    const verification = await verifyPassword(password, user.password_hash);
    if (!verification.ok) return errorResponse('Credenciales inválidas', 401);

    if (verification.upgradedHash) {
      const { error: upgradeError } = await supabaseAdmin
        .from('usuarios')
        .update({ password_hash: verification.upgradedHash })
        .eq('id', user.id);

      if (upgradeError) {
        console.error('No se pudo migrar password_hash a bcrypt', upgradeError);
      }
    }

    // Generar token aleatorio seguro
    const rawToken = crypto.randomUUID() + crypto.randomUUID();
    const tokenHash = await sha256Hex(rawToken);

    const expiresAt = new Date();
    expiresAt.setFullYear(expiresAt.getFullYear() + 100);

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
