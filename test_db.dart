import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  final url =
      'https://qwncrihpfckmuablqroa.supabase.co/rest/v1/usuarios?usuario=eq.admin&activo=eq.true&select=id,usuario,password_hash,rol,activo';
  final anonKey = 'sb_publishable_vqFcmjd5oRX_4DpSYcWLVA_SZ0fEv2a';

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
