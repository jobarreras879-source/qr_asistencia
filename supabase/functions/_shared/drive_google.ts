// Utility functions for Google OAuth2 and Drive API operations

// ─── OAuth2 Token Exchange ─────────────────────────────────────────────────

export interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  token_type: string;
  expires_in: number;
  scope?: string;
}

export interface LinkedAccount {
  access_token: string;
  refresh_token: string;
  email: string;
}

/**
 * Exchange a server auth code for access + refresh tokens.
 * Used during admin Drive linking.
 */
export async function exchangeAuthCode(
  serverAuthCode: string,
  clientId: string,
  clientSecret: string,
  redirectUri = '',
): Promise<LinkedAccount> {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code: serverAuthCode,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    }),
  });

  const data = await res.json();
  if (!res.ok || !data.access_token) {
    const details = [data.error, data.error_description]
      .filter((value) => typeof value === 'string' && value.trim().length > 0)
      .join(' - ');
    throw new Error(`OAuth exchange failed: ${details || 'unknown'}`);
  }
  if (!data.refresh_token) {
    throw new Error('No se recibió refresh_token. Asegúrate de usar access_type=offline y prompt=consent.');
  }

  // Get the email of the linked account
  const email = await getGoogleEmail(data.access_token);

  return {
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    email,
  };
}

/**
 * Get a new access token using a stored refresh token.
 */
export async function getAccessToken(
  refreshToken: string,
  clientId: string,
  clientSecret: string,
): Promise<string> {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      refresh_token: refreshToken,
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: 'refresh_token',
    }),
  });

  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(`Token refresh failed: ${data.error_description ?? data.error ?? 'unknown'}`);
  }
  return data.access_token;
}

async function getGoogleEmail(accessToken: string): Promise<string> {
  const res = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const data = await res.json();
  return data.email ?? 'unknown';
}

// ─── AES-256-GCM Encryption ───────────────────────────────────────────────

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function deriveKey(rawKey: string): Promise<CryptoKey> {
  // Derive a 256-bit key from the string using SHA-256
  const encoder = new TextEncoder();
  const keyData = encoder.encode(rawKey);
  const hashBuffer = await crypto.subtle.digest('SHA-256', keyData);

  return crypto.subtle.importKey(
    'raw',
    hashBuffer,
    { name: 'AES-GCM' },
    false,
    ['encrypt', 'decrypt'],
  );
}

/**
 * Encrypts plaintext using AES-256-GCM.
 * Returns a hex string: iv(24 hex chars) + ciphertext.
 */
export async function encryptToken(plaintext: string, keyString: string): Promise<string> {
  const key = await deriveKey(keyString);
  const iv = crypto.getRandomValues(new Uint8Array(12)); // 96-bit IV
  const encoder = new TextEncoder();

  const cipherBuffer = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    encoder.encode(plaintext),
  );

  const ivHex = bytesToHex(iv);
  const dataHex = bytesToHex(new Uint8Array(cipherBuffer));
  return ivHex + dataHex;
}

/**
 * Decrypts a hex string produced by encryptToken.
 */
export async function decryptToken(cipherHex: string, keyString: string): Promise<string> {
  const key = await deriveKey(keyString);
  const iv = hexToBytes(cipherHex.substring(0, 24));
  const cipherBytes = hexToBytes(cipherHex.substring(24));

  const plainBuffer = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv },
    key,
    cipherBytes,
  );

  return new TextDecoder().decode(plainBuffer);
}

// ─── Google Drive API Helpers ──────────────────────────────────────────────

export interface DriveFolder {
  id: string;
  name: string;
}

/**
 * Lists folders in Google Drive for the authenticated account.
 */
export async function listDriveFolders(accessToken: string): Promise<DriveFolder[]> {
  const params = new URLSearchParams({
    q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
    fields: 'files(id,name)',
    pageSize: '100',
    includeItemsFromAllDrives: 'true',
    supportsAllDrives: 'true',
  });

  const res = await fetch(
    `https://www.googleapis.com/drive/v3/files?${params}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );

  const data = await res.json();
  if (!res.ok) throw new Error(`Drive list failed: ${data.error?.message ?? 'unknown'}`);
  return (data.files ?? []) as DriveFolder[];
}

/**
 * Creates a folder in Google Drive.
 */
export async function createDriveFolder(
  name: string,
  accessToken: string,
): Promise<DriveFolder> {
  const res = await fetch('https://www.googleapis.com/drive/v3/files', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name,
      mimeType: 'application/vnd.google-apps.folder',
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(`Drive create folder failed: ${data.error?.message ?? 'unknown'}`);
  return { id: data.id, name: data.name };
}

/**
 * Uploads a JPEG file (base64 encoded) to a Drive folder.
 * Returns the created file's id and name.
 */
export async function uploadFileToDrive(
  fileName: string,
  imageBase64: string,
  folderId: string,
  accessToken: string,
): Promise<{ id: string; name: string }> {
  const imageBytes = Uint8Array.from(atob(imageBase64), (c) => c.charCodeAt(0));

  const boundary = '-------boundary_qr_asistencia';
  const delimiter = `\r\n--${boundary}\r\n`;
  const closeDelimiter = `\r\n--${boundary}--`;

  const metadata = JSON.stringify({
    name: fileName,
    parents: [folderId],
  });

  const metadataPart =
    delimiter +
    'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
    metadata;

  const mediaPart = '\r\n--' + boundary + '\r\n' + 'Content-Type: image/jpeg\r\n\r\n';

  // Build multipart body as Uint8Array
  const encoder = new TextEncoder();
  const metaBytes = encoder.encode(metadataPart);
  const mediaHeaderBytes = encoder.encode(mediaPart);
  const closeBytes = encoder.encode(closeDelimiter);

  const body = new Uint8Array(
    metaBytes.length + mediaHeaderBytes.length + imageBytes.length + closeBytes.length,
  );
  body.set(metaBytes, 0);
  body.set(mediaHeaderBytes, metaBytes.length);
  body.set(imageBytes, metaBytes.length + mediaHeaderBytes.length);
  body.set(closeBytes, metaBytes.length + mediaHeaderBytes.length + imageBytes.length);

  const res = await fetch(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': `multipart/related; boundary="${boundary}"`,
        'Content-Length': body.length.toString(),
      },
      body,
    },
  );

  const data = await res.json();
  if (!res.ok) throw new Error(`Drive upload failed: ${data.error?.message ?? 'unknown'}`);
  return { id: data.id, name: data.name };
}
