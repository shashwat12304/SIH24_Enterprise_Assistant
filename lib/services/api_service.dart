import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://127.0.0.1:8081';

  // ---------- Chat ----------

  static Future<Map<String, dynamic>> askQuestion(String question) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      throw ApiException(body['error'] ?? 'Bad request');
    } else {
      throw ApiException('Server error: ${response.statusCode}');
    }
  }

  // ---------- OCR ----------

  static Future<String> uploadImageForOcr(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/ocr'))
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode == 200) {
      return json['analysis'] ?? '';
    } else {
      throw ApiException(json['error'] ?? 'OCR failed');
    }
  }

  // ---------- PDF Upload ----------

  static Future<String> uploadPdf(String filePath) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_pdf'));
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('application', 'pdf'),
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode == 200) {
      return json['message'] ?? 'Uploaded';
    } else {
      throw ApiException(json['error'] ?? 'Upload failed');
    }
  }

  // ---------- Corpus ----------

  static Future<List<Map<String, dynamic>>> fetchCorpus(String type) async {
    final response = await http.get(Uri.parse('$baseUrl/corpus/$type'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['files'] ?? []);
    }
    return [];
  }

  // ---------- OTP ----------

  static Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['verified'] == true;
    }
    return false;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
