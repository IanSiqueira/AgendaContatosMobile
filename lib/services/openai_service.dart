// lib/services/openai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuotaExceededException implements Exception {
  @override
  String toString() =>
      'Desculpe, atingimos o limite de uso. Tente novamente mais tarde.';
}

class OpenAIService {
  final _key = dotenv.env['OPENAI_API_KEY']!;
  final _url = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String prompt) async {
    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_key',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (res.statusCode == 429) {
      throw QuotaExceededException();
    } else {
      throw Exception('Erro ${res.statusCode}: ${res.body}');
    }
  }
}
