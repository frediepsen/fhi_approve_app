import 'package:fhi_approve/api/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ContaDetalhe parseia JSON do backend', () {
    final c = ContaDetalhe.fromJson({
      'resumo': {
        'empresa': 1, 'sequencia': 1, 'titulo': 'TIT-1', 'emissao': null,
        'vencimento': '2026-11-20', 'valor': 150.00, 'fornecedorCodigo': 500,
        'fornecedorNome': 'XPTO', 'departamento': 5, 'departamentoDescricao': 'COMPRAS',
        'centroCusto': 100, 'centroCustoDescricao': 'ADM', 'notaFiscal': 12345, 'serie': '1',
      },
      'tipoVencimento': null, 'lancamento': null, 'desconto': 0, 'jurosDia': 0,
      'valorOriginal': 0, 'codigoBarras': null, 'observacao': null, 'situacao': 0,
      'motivoDecisao': null, 'usuarioDecisao': null, 'dataDecisao': null,
      'nota': {
        'sequencia': 900, 'numero': 12345, 'serie': '1', 'especie': null,
        'emissao': '2026-10-01', 'entrada': null, 'chaveNfe': null, 'totalProdutos': 150.00,
        'totalDesconto': 0, 'totalIpi': 0, 'totalFrete': 0, 'totalOutros': 0, 'observacao': null,
        'itens': [
          {'item': 1, 'produto': 42, 'descricao': 'PARAFUSO', 'quantidade': 10.000,
           'precoUnitario': 15.00000, 'desconto': 0, 'ipi': 0, 'total': 150.00}
        ],
      },
    });
    expect(c.resumo.vencimento, DateTime(2026, 11, 20));
    expect(c.resumo.emissao, isNull);
    expect(c.nota!.itens.single.total, 150.0);
    expect(c.situacao, ContaDetalhe.pendente);
  });
}
