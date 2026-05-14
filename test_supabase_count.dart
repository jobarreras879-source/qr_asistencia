import 'package:supabase_flutter/supabase_flutter.dart';

void test() async {
  final _supabase = Supabase.instance.client;

  var query = _supabase
          .from('registros')
          .count(CountOption.exact)
          .gte('fecha_hora', '2023-10-01')
          .lt('fecha_hora', '2023-10-02');

  if (true) {
    query = query.eq('usuario_logueado', 'octavio');
  }

  int count = await query;
  print(count);
}
