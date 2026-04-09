import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { ensureConfigSchema } from '../_shared/config_schema.ts';
import { validateAppSession } from '../_shared/session.ts';
import { getAccessToken, decryptToken, uploadFileToDrive } from '../_shared/drive_google.ts';

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Any authenticated app user can upload (supervisor or admin)
    try {
      await validateAppSession(req, supabaseAdmin);
    } catch (e) {
      return e as Response;
    }

    await ensureConfigSchema();

    const body = await req.json();
    const { nombreBase, imageBase64, usuario, proyecto, fechaHora } = body as {
      nombreBase?: string;
      imageBase64?: string;
      usuario?: string;
      proyecto?: string;
      fechaHora?: string;
    };

    if (!imageBase64) return errorResponse('Falta imageBase64', 400);

    // Read Drive config
    const { data: config, error: configError } = await supabaseAdmin
      .from('configuracion_global')
      .select('drive_admin_refresh_token_enc, drive_folder_id, drive_folder_name')
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle();

    if (configError) return errorResponse('Error leyendo configuración', 500);
    if (!config?.drive_admin_refresh_token_enc) {
      return errorResponse('Drive no configurado. El administrador debe vincular Google Drive primero.', 400);
    }
    if (!config?.drive_folder_id) {
      return errorResponse('Carpeta de Drive no configurada. El administrador debe seleccionar una carpeta.', 400);
    }

    const clientId = Deno.env.get('GOOGLE_CLIENT_ID')!;
    const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET')!;
    const encryptionKey = Deno.env.get('DRIVE_ENCRYPTION_KEY')!;

    // Refresh admin access token
    const refreshToken = await decryptToken(config.drive_admin_refresh_token_enc, encryptionKey);
    const accessToken = await getAccessToken(refreshToken, clientId, clientSecret);

    // Build filename: {nombreBase}_{YYYYMMDD_HHmmss}.jpg
    const now = fechaHora ? new Date(fechaHora) : new Date();
    const ts = now
      .toISOString()
      .replace(/[-:T]/g, '')
      .replace(/\..+/, '')
      .substring(0, 15);
    const safeName = (nombreBase ?? usuario ?? 'foto').replace(/[^a-zA-Z0-9_\-]/g, '_');
    const fileName = `${safeName}_${ts}.jpg`;

    // Upload to Drive under admin's folder
    const uploaded = await uploadFileToDrive(
      fileName,
      imageBase64,
      config.drive_folder_id,
      accessToken,
    );

    return jsonResponse({
      ok: true,
      fileId: uploaded.id,
      fileName: uploaded.name,
      folderName: config.drive_folder_name,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Error desconocido';
    return errorResponse(message, 500);
  }
});
