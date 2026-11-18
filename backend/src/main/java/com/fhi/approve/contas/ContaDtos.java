package com.fhi.approve.contas;

import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ContaDtos {

    private ContaDtos() {
    }

    /** pg1_situa */
    public static final int PENDENTE = 0;
    public static final int APROVADO = 1;
    public static final int REJEITADO = 2;

    public record ContaResumo(
            int empresa,
            long sequencia,
            String titulo,
            LocalDate emissao,
            LocalDate vencimento,
            BigDecimal valor,
            Long fornecedorCodigo,
            String fornecedorNome,
            long departamento,
            String departamentoDescricao,
            long centroCusto,
            String centroCustoDescricao,
            Long notaFiscal,
            String serie) {
    }

    public record ContaDetalhe(
            ContaResumo resumo,
            String tipoVencimento,
            LocalDate lancamento,
            BigDecimal desconto,
            BigDecimal jurosDia,
            BigDecimal valorOriginal,
            String codigoBarras,
            String observacao,
            int situacao,
            String motivoDecisao,
            Long usuarioDecisao,
            LocalDate dataDecisao,
            NotaFiscal nota) {
    }

    public record NotaFiscal(
            long sequencia,
            long numero,
            String serie,
            String especie,
            LocalDate emissao,
            LocalDate entrada,
            String chaveNfe,
            BigDecimal totalProdutos,
            BigDecimal totalDesconto,
            BigDecimal totalIpi,
            BigDecimal totalFrete,
            BigDecimal totalOutros,
            String observacao,
            List<ItemNota> itens) {
    }

    public record ItemNota(
            int item,
            long produto,
            String descricao,
            BigDecimal quantidade,
            BigDecimal precoUnitario,
            BigDecimal desconto,
            BigDecimal ipi,
            BigDecimal total) {
    }

    public record DecisaoRequest(@Size(max = 100) String motivo) {
    }

    public record DecisaoResponse(int empresa, long sequencia, int situacao) {
    }
}
