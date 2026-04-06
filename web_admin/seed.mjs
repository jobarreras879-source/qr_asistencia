import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

const envContent = fs.readFileSync('.env.local', 'utf-8');
const lines = envContent.split('\n');
let supabaseUrl = '';
let supabaseKey = '';

for (const line of lines) {
  if (line.startsWith('VITE_SUPABASE_URL=')) supabaseUrl = line.split('=')[1].trim();
  if (line.startsWith('VITE_SUPABASE_ANON_KEY=')) supabaseKey = line.split('=')[1].trim();
}

console.log('Connecting to', supabaseUrl);
const supabase = createClient(supabaseUrl, supabaseKey);

async function seed() {
  try {
    // 1. Insert Empresa
    const { data: empresa, error: empresaErr } = await supabase
      .from('empresas')
      .insert({ codigo: 'TEST', nombre: 'Demostración SA' })
      .select()
      .single();
    
    if (empresaErr) {
       console.log('Error inserting empresa, it might already exist.', empresaErr.message);
    }
    
    // Fetch empresa manually in case of error
    const { data: fetchEmp } = await supabase.from('empresas').select('*').limit(1).single();
    let empresa_id = fetchEmp ? fetchEmp.id : (empresa ? empresa.id : null);
    
    if (!empresa_id) throw new Error("Could not get or create empresa id");
    
    console.log('Empresa ID:', empresa_id);
    
    // 2. Insert Usuarios
    const { error: userErr } = await supabase
      .from('usuarios')
      .upsert([
        { empresa_id, usuario: 'jdoe', password_hash: '1234', nombre: 'John Doe', rol: 'USUARIO', activo: true },
        { empresa_id, usuario: 'msmith', password_hash: '1234', nombre: 'Maria Smith', rol: 'USUARIO', activo: true }
      ], { onConflict: 'empresa_id,usuario' });
      
    if (userErr) console.log('Error upserting users:', userErr.message);

    // 3. Insert Proyectos
    const { error: projectErr } = await supabase
      .from('proyecto')
      .upsert([
        { empresa_id, 'No.': 'PRJ-001', 'NameProyect': 'Torre Reforma', activo: true },
        { empresa_id, 'No.': 'PRJ-002', 'NameProyect': 'Plaza Central', activo: true }
      ], { onConflict: 'empresa_id,"No."' });
      
    if (projectErr) console.log('Error upserting projects:', projectErr.message);
    
    // 4. Fetch the users and projects
    const { data: users } = await supabase.from('usuarios').select('*').eq('empresa_id', empresa_id);
    const { data: projs } = await supabase.from('proyecto').select('*').eq('empresa_id', empresa_id);
    
    if (!users || !users.length || !projs || !projs.length) {
      console.log('Not enough data to create records');
      return;
    }
    
    console.log(`Found ${users.length} users and ${projs.length} projects`);

    // 5. Insert Registros (Asistencias today)
    const today = new Date().toISOString();
    const { error: regErr } = await supabase
      .from('registros')
      .insert([
        { 
          empresa_id, 
          proyecto_id: projs[0].id, 
          usuario_id: users[0].id, 
          "DPI": "1234567890101",
          nombre: users[0].nombre,
          proyecto: projs[0].NameProyect,
          tipo: 'Entrada',
          fecha_hora: today,
          usuario_logueado: 'admin'
        },
        { 
          empresa_id, 
          proyecto_id: projs[1].id, 
          usuario_id: users[1].id, 
          "DPI": "9876543210101",
          nombre: users[1].nombre,
          proyecto: projs[1].NameProyect,
          tipo: 'Entrada',
          fecha_hora: today,
          usuario_logueado: 'admin'
        }
      ]);
      
    if (regErr) console.log('Error inserting registros:', regErr.message);
    else console.log('Successfully inserted registros!');
    
  } catch (err) {
    console.error('Seed script error:', err);
  }
}

seed();
