import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const INTERNAL_DOMAIN = 'avsingenieria.com';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Cliente con service role (privilegios de Admin)
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verificar token del solicitante
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ ok: false, message: 'Sin autorización' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401
      });
    }
    const token = authHeader.replace('Bearer ', '');

    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({ ok: false, message: 'Token inválido o expirado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401
      });
    }

    // Verificar que el caller sea ADMIN
    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from('perfiles')
      .select('rol')
      .eq('id', user.id)
      .single();

    if (profileError || callerProfile?.rol !== 'ADMIN') {
      return new Response(JSON.stringify({
        ok: false, errorCode: 'not_admin',
        message: 'Acceso denegado: Se requiere rol ADMIN.'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403
      });
    }

    const body = await req.json();
    const action = body.action as string;
    const targetId = body.targetId as string | undefined;
    const usuario = (body.usuario as string | undefined)?.trim();
    const password = body.password as string | undefined;
    const rol = body.rol as string | undefined;
    // emailReal: si el admin puso un correo real de Gmail/empresa para recovery
    const emailReal = (body.emailReal as string | undefined)?.trim().toLowerCase();

    if (!action) throw new Error('Falta la acción (create, update, delete)');

    // El email que usamos para auth: preferimos el email real si viene, si no generamos el interno
    const internalEmail = usuario ? `${usuario.toLowerCase()}@${INTERNAL_DOMAIN}` : undefined;
    const authEmail = emailReal || internalEmail;

    // ─── CREATE ──────────────────────────────────────────────────────
    if (action === 'create') {
      if (!usuario || !password || !rol) throw new Error('Faltan campos: usuario, password, rol');
      if (!authEmail) throw new Error('No se pudo determinar el email del usuario');

      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: authEmail,
        password,
        email_confirm: true,
        user_metadata: { usuario: usuario.toUpperCase(), rol },
      });

      if (createError) throw createError;

      if (newUser.user) {
        await supabaseAdmin.from('perfiles').upsert({
          id: newUser.user.id,
          usuario: usuario.toUpperCase(),
          rol,
        });
      }

      return new Response(JSON.stringify({
        ok: true, userId: newUser.user?.id, email: authEmail
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // ─── UPDATE ──────────────────────────────────────────────────────
    else if (action === 'update') {
      if (!targetId) throw new Error('Se requiere targetId para actualizar');

      const updatePayload: Record<string, unknown> = { user_metadata: {} };

      if (authEmail) {
        updatePayload.email = authEmail;
        updatePayload.email_confirm = true;
      }
      if (usuario) (updatePayload.user_metadata as Record<string, unknown>).usuario = usuario.toUpperCase();
      if (rol) (updatePayload.user_metadata as Record<string, unknown>).rol = rol;
      if (password && password.length >= 6) updatePayload.password = password;

      const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(targetId, updatePayload);
      if (updateError) throw updateError;

      const profilePayload: Record<string, unknown> = {};
      if (usuario) profilePayload.usuario = usuario.toUpperCase();
      if (rol) profilePayload.rol = rol;

      if (Object.keys(profilePayload).length > 0) {
        await supabaseAdmin.from('perfiles').update(profilePayload).eq('id', targetId);
      }

      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ─── DELETE ──────────────────────────────────────────────────────
    else if (action === 'delete') {
      if (!targetId) throw new Error('Se requiere targetId para eliminar');

      const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(targetId, false);
      if (deleteError) throw deleteError;

      // El CASCADE de la FK en perfiles debería limpiarlo, pero por si acaso:
      await supabaseAdmin.from('perfiles').delete().eq('id', targetId);

      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    else {
      throw new Error(`Acción no reconocida: ${action}`);
    }

  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Error desconocido';
    return new Response(JSON.stringify({ ok: false, errorCode: 'execution_failed', message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400
    });
  }
});
