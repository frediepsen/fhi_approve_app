import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../main.dart';
import '../theme.dart';
import 'conta_detalhe_screen.dart';

class ContasScreen extends StatefulWidget {
  const ContasScreen({super.key});

  @override
  State<ContasScreen> createState() => _ContasScreenState();
}

class _ContasScreenState extends State<ContasScreen> {
  late Future<List<ContaResumo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<List<ContaResumo>> _carregar() async {
    try {
      return await ApiClient.instance.listarContas();
    } on ApiException catch (e) {
      if (e.naoAutorizado && mounted) await irParaLogin(context);
      rethrow;
    }
  }

  Future<void> _recarregar() async {
    final f = _carregar();
    setState(() => _future = f);
    await f.catchError((_) => <ContaResumo>[]);
  }

  Future<void> _abrir(ContaResumo c) async {
    final decidiu = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ContaDetalheScreen(empresa: c.empresa, sequencia: c.sequencia)));
    if (decidiu == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a aprovar'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => irParaLogin(context),
          ),
        ],
      ),
      body: FutureBuilder<List<ContaResumo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Mensagem(
              icone: Icons.error_outline,
              texto: snap.error.toString(),
              acao: FilledButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
            );
          }
          final contas = snap.data!;
          if (contas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(children: const [
                SizedBox(height: 120),
                _Mensagem(icone: Icons.check_circle_outline, texto: 'Nenhuma conta pendente de aprovação'),
              ]),
            );
          }
          final total = contas.fold<double>(0, (s, c) => s + c.valor);
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: contas.length + 1,
              separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 10),
              itemBuilder: (context, i) {
                if (i == 0) return _Resumo(quantidade: contas.length, total: total);
                return _ContaCard(conta: contas[i - 1], onTap: () => _abrir(contas[i - 1]));
              },
            ),
          );
        },
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final int quantidade;
  final double total;
  const _Resumo({required this.quantidade, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Cores.primaria,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total pendente',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(moeda(total),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(quantidade == 1 ? '1 conta' : '$quantidade contas',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
        ),
      ]),
    );
  }
}

class _ContaCard extends StatelessWidget {
  final ContaResumo conta;
  final VoidCallback onTap;
  const _ContaCard({required this.conta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venc = conta.vencimento;
    final hoje = DateUtils.dateOnly(DateTime.now());
    final dias = venc?.difference(hoje).inDays;

    final (Color corVenc, Color fundoVenc, String textoVenc) = switch (dias) {
      null => (Cores.textoSecundario, Cores.fundo, 'Sem vencimento'),
      < 0 => (Cores.rejeitar, Cores.rejeitarClaro, 'Vencida · ${data(venc)}'),
      0 => (Cores.alerta, Cores.alertaClaro, 'Vence hoje'),
      <= 3 => (Cores.alerta, Cores.alertaClaro, 'Vence ${data(venc)}'),
      _ => (Cores.textoSecundario, Cores.fundo, 'Vence ${data(venc)}'),
    };

    final documento = [
      if (conta.titulo != null) 'Título ${conta.titulo}',
      if (conta.notaFiscal != null) 'NF ${conta.notaFiscal}',
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, color: corVenc == Cores.textoSecundario ? Cores.primaria : corVenc),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(
                        conta.fornecedorNome ?? 'Fornecedor ${conta.fornecedorCodigo ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(moeda(conta.valor),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ]),
                  if (documento.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(documento,
                        style: theme.textTheme.bodySmall?.copyWith(color: Cores.textoSecundario)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _Etiqueta(
                        icone: Icons.event_outlined,
                        texto: textoVenc,
                        cor: corVenc,
                        fundo: fundoVenc),
                    _Etiqueta(
                        icone: Icons.apartment_outlined,
                        texto: conta.departamentoDescricao ?? 'Depto ${conta.departamento}',
                        cor: Cores.textoSecundario,
                        fundo: Cores.fundo),
                    _Etiqueta(
                        icone: Icons.business_outlined,
                        texto: 'Emp. ${conta.empresa}',
                        cor: Cores.textoSecundario,
                        fundo: Cores.fundo),
                  ]),
                ]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Cores.textoSecundario),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;
  final Color fundo;
  const _Etiqueta({required this.icone, required this.texto, required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cor)),
        ),
      ]),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Widget? acao;
  const _Mensagem({required this.icone, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          if (acao != null) ...[const SizedBox(height: 16), acao!],
        ]),
      ),
    );
  }
}
