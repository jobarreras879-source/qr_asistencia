import 'package:supabase/supabase.dart';

void main() async {
  final url = 'https://qwncrihpfckmuablqroa.supabase.co';
  final anonKey = 'sb_publishable_vqFcmjd5oRX_4DpSYcWLVA_SZ0fEv2a';
  
  final client = SupabaseClient(url, anonKey);
  try {
    print('Intentando login con test@avsingenieria.internal y pass: test1234');
    final res = await client.auth.signInWithPassword(email: 'test@avsingenieria.internal', password: 'test1234');
    print('EXITO! ' + res.toString());
  } catch(e) {
    print('ERROR CON test1234: ' + e.toString());
  }
}
