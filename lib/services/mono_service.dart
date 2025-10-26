import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MonoService {
  final String _publicKey = dotenv.env['MONO_PUBLIC_KEY']!;
  final String _secretKey = dotenv.env['MONO_SECRET_KEY']!;
  final String _baseUrl = 'https://api.withmono.com';

  // Example: Get test accounts
  Future<http.Response> getAccounts() async {
    final url = Uri.parse('$_baseUrl/accounts');
    return await http.get(
      url,
      headers: {'mono-sec-key': _secretKey, 'Content-Type': 'application/json'},
    );
  }
}
