import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // Manejo de pre-flight requests para CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // 1. Instanciar cliente con Service Role para operaciones administrativas
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Extraer el token del usuario que hace la petición
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Falta el token de autorización');
    }
    const token = authHeader.replace('Bearer ', '');

    // 3. Verificar la identidad y rol del usuario llamante
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      throw new Error('Token inválido o expirado');
    }

    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from('perfiles')
      .select('rol')
      .eq('id', user.id)
      .single();

    if (profileError || callerProfile?.rol !== 'ADMIN') {
      return new Response(JSON.stringify({
        ok: false,
        errorCode: 'not_admin',
        message: 'Acceso denegado: Se requiere rol ADMIN.'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      });
    }

    // 4. Parsear el body de la petición
    const body = await req.json();
    const action = body.action; // 'create', 'update', 'delete'
    const targetId = body.targetId;
    const usuario = body.usuario?.trim();
    const password = body.password;
    const rol = body.rol;

    if (!action) {
      throw new Error('Debe proporcionar una acción (create, update, delete)');
    }

    const internalDomain = '@avsingenieria.internal';
    const email = usuario ? `${usuario.toLowerCase()}${internalDomain}` : undefined;

    // --- ACCIÓN: CREAR ---
    if (action === 'create') {
      if (!usuario || !password || !rol) {
        throw new Error('Usuario, password y rol son obligatorios para crear');
      }

      // Crear en auth.users
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: email,
        password: password,
        email_confirm: true,
        user_metadata: { usuario: usuario.toUpperCase(), rol: rol },
      });

      if (createError) throw createError;

      // upsert a perfiles lo hace el trigger automáticamente, pero por si acaso fallara o
      // quisieramos asegurarnos, lo actualizamos nosotros:
      if (newUser.user) {
        await supabaseAdmin.from('perfiles').upsert({
          id: newUser.user.id,
          usuario: usuario.toUpperCase(),
          rol: rol
        });
      }

      return new Response(JSON.stringify({
        ok: true,
        userId: newUser.user?.id,
        usuario,
        email,
        rol
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // --- ACCIÓN: ACTUALIZAR ---
    else if (action === 'update') {
      if (!targetId) throw new Error('Se requiere targetId para actualizar');

      const updatePayload: any = {
        user_metadata: {}
      };

      if (email) {
        updatePayload.email = email;
        updatePayload.email_confirm = true;
      }
      if (usuario) updatePayload.user_metadata.usuario = usuario.toUpperCase();
      if (rol) updatePayload.user_metadata.rol = rol;
      if (password && password.length >= 6) updatePayload.password = password;

      const { data: updatedUser, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
        targetId,
        updatePayload
      );

      if (updateError) throw updateError;

      // Sincronizar tabla perfiles
      const profilePayload: any = {};
      if (usuario) profilePayload.usuario = usuario.toUpperCase();
      if (rol) profilePayload.rol = rol;

      if (Object.keys(profilePayload).length > 0) {
        await supabaseAdmin.from('perfiles').update(profilePayload).eq('id', targetId);
      }

      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // --- ACCIÓN: ELIMINAR ---
    else if (action === 'delete') {
      if (!targetId) throw new Error('Se requiere targetId para eliminar');

      const { data, error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
        targetId,
        /* shouldSoftDelete */ false
      );

      if (deleteError) throw deleteError;

      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    else {
      throw new Error('Acción no reconocida');
    }

  } catch (error: any) {
    return new Response(JSON.stringify({
      ok: false,
      errorCode: 'execution_failed',
      message: error.message || 'Error desconocido'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
