import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/account_model.dart';
import 'models/transaction_model.dart';
import 'models/category_model.dart';

class ApiService {
  static String get baseUrl {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://91.108.122.163:3000/api';
    } catch (_) {
      return 'http://91.108.122.163:3000/api';
    }
  }
  String? _userId;

  void setUserId(String? id) => _userId = id;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_userId != null) 'x-user-id': _userId!,
  };

  static Duration get timeoutDuration => Duration(milliseconds: int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000);

  // Helper for UTF-8 decoding
  static dynamic _decode(http.Response res) {
    try {
      final body = utf8.decode(res.bodyBytes);
      if (body.isEmpty) return {};
      return jsonDecode(body);
    } catch (e) {
      debugPrint('JSON decode error: $e. Status: ${res.statusCode}');
      return {'error': 'Ошибка сервера (${res.statusCode})'};
    }
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> login(String login, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    ).timeout(timeoutDuration);
    final data = _decode(res);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Ошибка входа');
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String login,
    required String password,
    required String name,
    required String currency,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password, 'name': name, 'currency': currency}),
    ).timeout(timeoutDuration);
    final data = _decode(res);
    if (res.statusCode == 409) throw Exception('Логин уже занят');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(data['error'] ?? 'Ошибка регистрации');
    return data;
  }

  // ── Accounts ──
  Future<List<AccountModel>> fetchAccounts() async {
    final res = await http.get(Uri.parse('$baseUrl/accounts'), headers: _headers).timeout(timeoutDuration);
    final data = _decode(res);
    if (data is List) return data.map((e) => AccountModel.fromJson(e)).toList();
    return [];
  }

  Future<AccountModel> addAccount(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl/accounts'), headers: _headers, body: jsonEncode(body)).timeout(timeoutDuration);
    return AccountModel.fromJson(_decode(res));
  }

  Future<void> deleteAccount(String id) async {
    await http.delete(Uri.parse('$baseUrl/accounts/$id'), headers: _headers).timeout(timeoutDuration);
  }

  // ── Transactions ──
  Future<List<TransactionModel>> fetchTransactions({String? accountId}) async {
    final url = accountId != null ? '$baseUrl/transactions?accountId=$accountId' : '$baseUrl/transactions';
    final res = await http.get(Uri.parse(url), headers: _headers).timeout(timeoutDuration);
    final data = _decode(res);
    if (data is List) return data.map((e) => TransactionModel.fromJson(e)).toList();
    return [];
  }

  Future<TransactionModel> addTransaction(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl/transactions'), headers: _headers, body: jsonEncode(body)).timeout(timeoutDuration);
    return TransactionModel.fromJson(_decode(res));
  }

  Future<void> deleteTransaction(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/transactions/$id'), headers: _headers).timeout(timeoutDuration);
    if (res.statusCode != 200 && res.statusCode != 204) {
      final data = _decode(res);
      throw Exception(data['error'] ?? 'Ошибка при удалении');
    }
  }

  // ── Categories ──
  Future<List<CategoryModel>> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers).timeout(timeoutDuration);
    final data = _decode(res);
    if (data is List) return data.map((e) => CategoryModel.fromJson(e)).toList();
    return [];
  }

  Future<CategoryModel> addCategory(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl/categories'), headers: _headers, body: jsonEncode(body)).timeout(timeoutDuration);
    return CategoryModel.fromJson(_decode(res));
  }

  Future<void> deleteCategory(String id) async {
    await http.delete(Uri.parse('$baseUrl/categories/$id'), headers: _headers).timeout(timeoutDuration);
  }

  // ── Currency rates ──
  Future<Map<String, double>> fetchRates() async {
    final res = await http.get(Uri.parse('$baseUrl/currency')).timeout(timeoutDuration);
    final data = _decode(res) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
