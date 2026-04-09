import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { errorResponse } from './cors.ts';

export interface AppSession {
  id: string;
  usuarioId: number;
  usuario: string;
  rol: string;
  expiresAt: string;
}

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Validates the app session from the Authorization header.
 * Returns the session data or throws a Response with 401/403.
 */
export async function validateAppSession(
  req: Request,
  supabaseAdmin: SupabaseClient,
): Promise<AppSession> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    throw errorResponse('Sin autorización', 401);
  }

  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) throw errorResponse('Token vacío', 401);

  const tokenHash = await sha256Hex(token);

  const { data: session, error } = await supabaseAdmin
    .from('app_sessions')
    .select('id, usuario_id, usuario, rol, expires_at')
    .eq('token_hash', tokenHash)
    .is('revoked_at', null)
    .gt('expires_at', new Date().toISOString())
    .maybeSingle();

  if (error) throw errorResponse('Error verificando sesión', 500);
  if (!session) throw errorResponse('Sesión inválida o expirada', 401);

  const { data: currentUser, error: userError } = await supabaseAdmin
    .from('usuarios')
    .select('usuario, rol, activo')
    .eq('id', session.usuario_id)
    .maybeSingle();

  if (userError) throw errorResponse('Error verificando usuario actual', 500);
  if (!currentUser || currentUser.activo !== true) {
    await supabaseAdmin
      .from('app_sessions')
      .update({ revoked_at: new Date().toISOString() })
      .eq('id', session.id);
    throw errorResponse('Sesión inválida o usuario inactivo', 401);
  }

  if (currentUser.usuario !== session.usuario || currentUser.rol !== session.rol) {
    await supabaseAdmin
      .from('app_sessions')
      .update({
        usuario: currentUser.usuario,
        rol: currentUser.rol,
      })
      .eq('id', session.id);
  }

  return {
    id: session.id,
    usuarioId: session.usuario_id,
    usuario: currentUser.usuario,
    rol: currentUser.rol,
    expiresAt: session.expires_at,
  };
}

/** Throws 403 if the session role is not ADMIN */
export function requireAdmin(session: AppSession): void {
  if (session.rol !== 'ADMIN') {
    throw errorResponse('Acceso denegado: se requiere rol ADMIN', 403);
  }
}
