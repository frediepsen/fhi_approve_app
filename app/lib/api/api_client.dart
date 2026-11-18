import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.25.26:8080');

class ApiException implements Exception {
  final int status;
  final String mensagem;
  ApiException(this.status, this.mensagem);

  bool get naoAutorizado => status == 401;

  @override
  String toString() => mensagem;
}

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  static const _tokenKey = 'token';
  static const _nomeKey = 'nome';
  static const _expKey = 'expira';
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? nomeUsuario;

  /// Carrega sessão salva; retorna true se ainda válida.
  Future<bool> restaurarSessao() async {
    final token = await _storage.read(key: _tokenKey);
    final exp = await _storage.read(key: _expKey);
    if (token == null || exp == null || DateTime.parse(exp).isBefore(DateTime.now())) {
      await logout();
      return false;
    }
    _token = token;
    nomeUsuario = await _storage.read(key: _nomeKey);
    return true;
  }

  Future<void> login(int codigo, String senha) async {
    final res = await _post('/api/auth/login', {'codigo': codigo, 'senha': senha}, auth: false);
    final s = Sessao.fromJson(res);
    _token = s.token;
    nomeUsuario = s.nome;
    await _storage.write(key: _tokenKey, value: s.token);
    await _storage.write(key: _expKey, value: s.expiraEm.toIso8601String());
    await _storage.write(key: _nomeKey, value: s.nome ?? '');
  }

  Future<void> logout() async {
    _token = null;
    nomeUsuario = null;
    await _storage.deleteAll();
  }

  Future<List<ContaResumo>> listarContas() async {
    final res = await _get('/api/contas') as List;
    return res.map((e) => ContaResumo.fromJson(e)).toList();
  }

  Future<ContaDetalhe> detalhe(int empresa, int sequencia) async {
    return ContaDetalhe.fromJson(await _get('/api/contas/$empresa/$sequencia'));
  }

  Future<void> aprovar(int empresa, int sequencia, {String? observacao}) =>
      _post('/api/contas/$empresa/$sequencia/aprovar', {'motivo': observacao});

  Future<void> rejeitar(int empresa, int sequencia, String motivo) =>
      _post('/api/contas/$empresa/$sequencia/rejeitar', {'motivo': motivo});

  Map<String, String> _headers({bool auth = true}) => {
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _get(String path) async {
    final r = await _send(() => http.get(Uri.parse('$apiBaseUrl$path'), headers: _headers()));
    return _handle(r);
  }

  Future<dynamic> _post(String path, Object body, {bool auth = true}) async {
    final r = await _send(() => http.post(Uri.parse('$apiBaseUrl$path'),
        headers: _headers(auth: auth), body: jsonEncode(body)));
    return _handle(r);
  }

  Future<http.Response> _send(Future<http.Response> Function() fn) async {
    try {
      return await fn().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException(0, 'Não foi possível conectar ao servidor');
    }
  }

  dynamic _handle(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map && body['erro'] != null
        ? body['erro'] as String
        : (r.statusCode == 401 ? 'Sessão expirada, faça login novamente' : 'Erro ${r.statusCode}');
    throw ApiException(r.statusCode, msg);
  }
}
