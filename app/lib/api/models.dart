DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);
double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();

class Sessao {
  final String token;
  final int codigo;
  final String? nome;
  final DateTime expiraEm;

  Sessao({required this.token, required this.codigo, this.nome, required this.expiraEm});

  factory Sessao.fromJson(Map<String, dynamic> j) => Sessao(
        token: j['token'],
        codigo: j['codigo'],
        nome: j['nome'],
        expiraEm: DateTime.parse(j['expiraEm']),
      );
}

class ContaResumo {
  final int empresa;
  final int sequencia;
  final String? titulo;
  final DateTime? emissao;
  final DateTime? vencimento;
  final double valor;
  final int? fornecedorCodigo;
  final String? fornecedorNome;
  final int departamento;
  final String? departamentoDescricao;
  final int centroCusto;
  final String? centroCustoDescricao;
  final int? notaFiscal;
  final String? serie;

  ContaResumo.fromJson(Map<String, dynamic> j)
      : empresa = j['empresa'],
        sequencia = j['sequencia'],
        titulo = j['titulo'],
        emissao = _date(j['emissao']),
        vencimento = _date(j['vencimento']),
        valor = _num(j['valor']),
        fornecedorCodigo = j['fornecedorCodigo'],
        fornecedorNome = j['fornecedorNome'],
        departamento = j['departamento'],
        departamentoDescricao = j['departamentoDescricao'],
        centroCusto = j['centroCusto'],
        centroCustoDescricao = j['centroCustoDescricao'],
        notaFiscal = j['notaFiscal'],
        serie = j['serie'];
}

class ItemNota {
  final int item;
  final int produto;
  final String? descricao;
  final double quantidade;
  final double precoUnitario;
  final double desconto;
  final double ipi;
  final double total;

  ItemNota.fromJson(Map<String, dynamic> j)
      : item = j['item'],
        produto = j['produto'],
        descricao = j['descricao'],
        quantidade = _num(j['quantidade']),
        precoUnitario = _num(j['precoUnitario']),
        desconto = _num(j['desconto']),
        ipi = _num(j['ipi']),
        total = _num(j['total']);
}

class NotaFiscal {
  final int numero;
  final String? serie;
  final String? especie;
  final DateTime? emissao;
  final DateTime? entrada;
  final String? chaveNfe;
  final double totalProdutos;
  final double totalDesconto;
  final double totalIpi;
  final double totalFrete;
  final double totalOutros;
  final String? observacao;
  final List<ItemNota> itens;

  NotaFiscal.fromJson(Map<String, dynamic> j)
      : numero = j['numero'],
        serie = j['serie'],
        especie = j['especie'],
        emissao = _date(j['emissao']),
        entrada = _date(j['entrada']),
        chaveNfe = j['chaveNfe'],
        totalProdutos = _num(j['totalProdutos']),
        totalDesconto = _num(j['totalDesconto']),
        totalIpi = _num(j['totalIpi']),
        totalFrete = _num(j['totalFrete']),
        totalOutros = _num(j['totalOutros']),
        observacao = j['observacao'],
        itens = (j['itens'] as List).map((e) => ItemNota.fromJson(e)).toList();
}

class ContaDetalhe {
  static const pendente = 0;
  static const aprovado = 1;
  static const rejeitado = 2;

  final ContaResumo resumo;
  final String? tipoVencimento;
  final DateTime? lancamento;
  final double desconto;
  final double jurosDia;
  final double valorOriginal;
  final String? codigoBarras;
  final String? observacao;
  final int situacao;
  final String? motivoDecisao;
  final NotaFiscal? nota;

  ContaDetalhe.fromJson(Map<String, dynamic> j)
      : resumo = ContaResumo.fromJson(j['resumo']),
        tipoVencimento = j['tipoVencimento'],
        lancamento = _date(j['lancamento']),
        desconto = _num(j['desconto']),
        jurosDia = _num(j['jurosDia']),
        valorOriginal = _num(j['valorOriginal']),
        codigoBarras = j['codigoBarras'],
        observacao = j['observacao'],
        situacao = j['situacao'],
        motivoDecisao = j['motivoDecisao'],
        nota = j['nota'] == null ? null : NotaFiscal.fromJson(j['nota']);
}
