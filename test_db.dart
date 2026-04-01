import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pfdxayabkkzyacpcsjcm.supabase.co',
  );
  const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-W1dVl1qtcS4CzAbXAO4FQ_NYsuq9z7',
  );
  final url =
      '$supabaseUrl/rest/v1/usuarios?usuario=eq.admin&activo=eq.true&select=id,usuario,password_hash,rol,activo';

  final uri = Uri.parse(url);
  final response = await http.get(
    uri,
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'},
  );

  print('HTTP Status: ${response.statusCode}');
  print('Response Body: ${response.body}');

  final typedPassword = 'admin1';
  final hash = sha256.convert(utf8.encode(typedPassword)).toString();
  print('Typed Hash: $hash');
}
