import 'dart:convert';
import 'package:http/http.dart' as http;

Future scanApp(List features) async {
  final res = await http.post(
    Uri.parse("http://localhost:8000/analyze"),
    body: jsonEncode({"features": features}),
  );

  return jsonDecode(res.body);
}
