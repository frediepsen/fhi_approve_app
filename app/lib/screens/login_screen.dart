import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import 'contas_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ApiClient.instance.login(int.parse(_codigo.text), _senha.text);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const ContasScreen()));
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.fact_check_outlined, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Aprovação de Contas a Pagar',
                        textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _codigo,
                      decoration: const InputDecoration(
                          labelText: 'Código do usuário',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o código' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Text(_erro!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: _carregando
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
