import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api/api_client.dart';
import 'screens/contas_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final logado = await ApiClient.instance.restaurarSessao();
  runApp(FhiApproveApp(logado: logado));
}

class FhiApproveApp extends StatelessWidget {
  final bool logado;
  const FhiApproveApp({super.key, required this.logado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprovação de Contas',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      themeMode: ThemeMode.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: logado ? const ContasScreen() : const LoginScreen(),
    );
  }
}

/// Volta para o login (usado quando a API retorna 401).
Future<void> irParaLogin(BuildContext context) async {
  await ApiClient.instance.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
}
