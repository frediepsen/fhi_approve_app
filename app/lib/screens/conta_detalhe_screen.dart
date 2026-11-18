import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../main.dart';
import '../theme.dart';

class ContaDetalheScreen extends StatefulWidget {
  final int empresa;
  final int sequencia;
  const ContaDetalheScreen({super.key, required this.empresa, required this.sequencia});

  @override
  State<ContaDetalheScreen> createState() => _ContaDetalheScreenState();
}

class _ContaDetalheScreenState extends State<ContaDetalheScreen> {
  late Future<ContaDetalhe> _future;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<ContaDetalhe> _carregar() async {
    try {
      return await ApiClient.instance.detalhe(widget.empresa, widget.sequencia);
    } on ApiException catch (e) {
      if (e.naoAutorizado && mounted) await irParaLogin(context);
      rethrow;
    }
  }

  Future<void> _aprovar() async {
    final obs = await _dialogoTexto(
      titulo: 'Aprovar conta',
      rotulo: 'Observação (opcional)',
      confirmar: 'Aprovar',
      obrigatorio: false,
      cor: Cores.aprovar,
    );
    if (obs == null) return;
    await _enviar(() => ApiClient.instance
        .aprovar(widget.empresa, widget.sequencia, observacao: obs.isEmpty ? null : obs),
        'Conta aprovada');
  }

  Future<void> _rejeitar() async {
    final motivo = await _dialogoTexto(
      titulo: 'Rejeitar conta',
      rotulo: 'Motivo da rejeição',
      confirmar: 'Rejeitar',
      obrigatorio: true,
      cor: Cores.rejeitar,
    );
    if (motivo == null) return;
    await _enviar(
        () => ApiClient.instance.rejeitar(widget.empresa, widget.sequencia, motivo), 'Conta rejeitada');
  }

  Future<void> _enviar(Future<void> Function() acao, String sucesso) async {
    setState(() => _enviando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await acao();
      messenger.showSnackBar(SnackBar(content: Text(sucesso)));
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (e.naoAutorizado && mounted) return irParaLogin(context);
      messenger.showSnackBar(SnackBar(content: Text(e.mensagem)));
      // 409: já decidida por outro usuário -> voltar e atualizar a lista
      if (e.status == 409 && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<String?> _dialogoTexto({
    required String titulo,
    required String rotulo,
    required String confirmar,
    required bool obrigatorio,
    required Color cor,
  }) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(titulo),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              maxLength: 100,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
              validator: (v) =>
                  obrigatorio && (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cor, foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, ctrl.text.trim());
              },
              child: Text(confirmar),
            ),
          ],
        );
      },
    ).whenComplete(ctrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conta ${widget.empresa}/${widget.sequencia}')),
      body: FutureBuilder<ContaDetalhe>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snap.error.toString()),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _future = _carregar()),
                  child: const Text('Tentar novamente'),
                ),
              ]),
            );
          }
          return _Conteudo(conta: snap.data!);
        },
      ),
      bottomNavigationBar: FutureBuilder<ContaDetalhe>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.situacao != ContaDetalhe.pendente) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Cores.borda)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _enviando ? null : _rejeitar,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Rejeitar'),
                      style: botaoRejeitar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _enviando ? null : _aprovar,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded),
                      label: const Text('Aprovar'),
                      style: botaoAprovar(),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  final ContaDetalhe conta;
  const _Conteudo({required this.conta});

  @override
  Widget build(BuildContext context) {
    final r = conta.resumo;
    final nf = conta.nota;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Cabecalho(conta: conta),
        const SizedBox(height: 16),
        _Secao(titulo: 'Conta a pagar', linhas: [
          ('Fornecedor', r.fornecedorNome ?? '${r.fornecedorCodigo ?? '-'}'),
          ('Título', r.titulo ?? '-'),
          ('Valor', moeda(r.valor)),
          if (conta.valorOriginal != 0 && conta.valorOriginal != r.valor)
            ('Valor original', moeda(conta.valorOriginal)),
          if (conta.desconto != 0) ('Desconto', moeda(conta.desconto)),
          if (conta.jurosDia != 0) ('Juros/dia', moeda(conta.jurosDia)),
          ('Emissão', data(r.emissao)),
          ('Vencimento', data(r.vencimento)),
          if (conta.tipoVencimento != null) ('Tipo venc.', conta.tipoVencimento!),
          ('Lançamento', data(conta.lancamento)),
          ('Empresa', '${r.empresa}'),
          ('Departamento', '${r.departamento} - ${r.departamentoDescricao ?? ''}'),
          ('Centro de custo', '${r.centroCusto} - ${r.centroCustoDescricao ?? ''}'),
          if (conta.codigoBarras != null) ('Cód. barras', conta.codigoBarras!),
          if (conta.observacao != null) ('Observação', conta.observacao!),
          if (conta.situacao != ContaDetalhe.pendente)
            ('Situação',
                conta.situacao == ContaDetalhe.aprovado ? 'Aprovada' : 'Rejeitada'),
          if (conta.motivoDecisao != null) ('Motivo', conta.motivoDecisao!),
        ]),
        if (nf != null) ...[
          const SizedBox(height: 16),
          _Secao(titulo: 'Nota fiscal', linhas: [
            ('Número', '${nf.numero}${nf.serie != null ? ' / série ${nf.serie}' : ''}'),
            if (nf.especie != null) ('Espécie', nf.especie!),
            ('Emissão', data(nf.emissao)),
            ('Entrada', data(nf.entrada)),
            ('Produtos', moeda(nf.totalProdutos)),
            if (nf.totalDesconto != 0) ('Desconto', moeda(nf.totalDesconto)),
            if (nf.totalIpi != 0) ('IPI', moeda(nf.totalIpi)),
            if (nf.totalFrete != 0) ('Frete', moeda(nf.totalFrete)),
            if (nf.totalOutros != 0) ('Outros', moeda(nf.totalOutros)),
            if (nf.chaveNfe != null) ('Chave NF-e', nf.chaveNfe!),
            if (nf.observacao != null) ('Observação', nf.observacao!),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Itens (${nf.itens.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final it in nf.itens)
                  ListTile(
                    dense: true,
                    title: Text(it.descricao ?? 'Produto ${it.produto}'),
                    subtitle: Text(
                        '${it.produto} · ${quantidade(it.quantidade)} x ${moeda(it.precoUnitario)}'),
                    trailing: Text(moeda(it.total)),
                  ),
                if (nf.itens.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('Sem itens')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final ContaDetalhe conta;
  const _Cabecalho({required this.conta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = conta.resumo;
    final (String status, Color cor, Color fundo) = switch (conta.situacao) {
      ContaDetalhe.aprovado => ('Aprovada', Cores.aprovar, Cores.aprovarClaro),
      ContaDetalhe.rejeitado => ('Rejeitada', Cores.rejeitar, Cores.rejeitarClaro),
      _ => ('Pendente', Cores.alerta, Cores.alertaClaro),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r.fornecedorNome ?? 'Fornecedor ${r.fornecedorCodigo ?? '-'}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cor)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(moeda(r.valor),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Vencimento ${data(r.vencimento)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Cores.textoSecundario)),
        ]),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<(String, String)> linhas;
  const _Secao({required this.titulo, required this.linhas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: Cores.primaria)),
            const SizedBox(height: 10),
            for (final (k, v) in linhas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                      width: 120,
                      child: Text(k,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  Expanded(child: SelectableText(v)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
