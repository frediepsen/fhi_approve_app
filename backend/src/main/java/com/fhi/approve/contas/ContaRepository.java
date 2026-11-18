package com.fhi.approve.contas;

import com.fhi.approve.auth.Departamentos;
import com.fhi.approve.contas.ContaDtos.ContaDetalhe;
import com.fhi.approve.contas.ContaDtos.ContaResumo;
import com.fhi.approve.contas.ContaDtos.ItemNota;
import com.fhi.approve.contas.ContaDtos.NotaFiscal;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class ContaRepository {

    /** Data "vazia" usada pelo ERP como default das colunas date. */
    static final LocalDate DATA_VAZIA = LocalDate.of(1800, 1, 1);

    private static final String SELECT_BASE = """
            SELECT p.pg1_cdemp, p.pg1_seque, p.pg1_titul, p.pg1_dtemi, p.pg1_dtven, p.pg1_valor,
                   p.pg1_cdcli, f.cl1_nomec,
                   p.pg1_depto, d.dpt_descr, p.pg1_ccust, c.ccp_descr,
                   p.pg1_sqnf1, n.nf1_notaf, n.nf1_serie
            """;

    private static final String SELECT_DETALHE = SELECT_BASE + """
                 , p.pg1_tpven, p.pg1_dtlan, p.pg1_vldes, p.pg1_judia, p.pg1_vlror, p.pg1_nubco,
                   p.pg1_obser, p.pg1_situa, p.pg1_alf05, p.pg1_num05, p.pg1_data5
            """;

    private static final String FROM_JOINS = """
              FROM sci_fatpg1 p
              LEFT JOIN sci_deptop d ON d.dpt_codig = p.pg1_depto
              LEFT JOIN sci_ccusto c ON c.ccp_codig = p.pg1_ccust
              LEFT JOIN sci_fatcl1 f ON f.cl1_cdemp = p.pg1_clemp AND f.cl1_codig = p.pg1_cdcli
              LEFT JOIN sci_fatnf1 n ON n.nf1_seque = p.pg1_sqnf1
            """;

    /** Pendente = sem decisão e ainda não paga. */
    private static final String PENDENTE = """
               p.pg1_situa = 0
               AND p.pg1_dtpag = DATE '1800-01-01'
            """;

    private final NamedParameterJdbcTemplate jdbc;

    public ContaRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<ContaResumo> listarPendentes(Departamentos deptos) {
        MapSqlParameterSource params = new MapSqlParameterSource();
        return jdbc.query(SELECT_BASE + FROM_JOINS + """
                 WHERE""" + PENDENTE + filtroDepto(deptos, params) + """
                 ORDER BY p.pg1_dtven, p.pg1_cdemp, p.pg1_seque
                """, params, (rs, i) -> resumo(rs));
    }

    /** Restringe a pg1_depto, exceto quando o usuário tem acesso a todos os departamentos. */
    private static String filtroDepto(Departamentos deptos, MapSqlParameterSource params) {
        if (deptos.todos()) {
            return "\n";
        }
        params.addValue("deptos", deptos.codigos());
        return "\n   AND p.pg1_depto IN (:deptos)\n";
    }

    public Optional<ContaDetalhe> buscar(int cdemp, long seque, Departamentos deptos) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("cdemp", cdemp)
                .addValue("seque", seque);
        List<ContaDetalhe> list = jdbc.query(SELECT_DETALHE + FROM_JOINS + """
                 WHERE p.pg1_cdemp = :cdemp
                   AND p.pg1_seque = :seque
                """ + filtroDepto(deptos, params), params, (rs, i) -> {
            ContaResumo r = resumo(rs);
            BigDecimal num05 = rs.getBigDecimal("pg1_num05");
            BigDecimal sqnf1 = rs.getBigDecimal("pg1_sqnf1");
            NotaFiscal nota = sqnf1 == null ? null : buscarNota(sqnf1.longValue()).orElse(null);
            return new ContaDetalhe(
                    r,
                    trim(rs.getString("pg1_tpven")),
                    date(rs, "pg1_dtlan"),
                    rs.getBigDecimal("pg1_vldes"),
                    rs.getBigDecimal("pg1_judia"),
                    rs.getBigDecimal("pg1_vlror"),
                    trim(rs.getString("pg1_nubco")),
                    trim(rs.getString("pg1_obser")),
                    rs.getInt("pg1_situa"),
                    trim(rs.getString("pg1_alf05")),
                    num05 == null || num05.signum() == 0 ? null : num05.longValue(),
                    date(rs, "pg1_data5"),
                    nota);
        });
        return list.stream().findFirst();
    }

    private Optional<NotaFiscal> buscarNota(long sqnf1) {
        List<ItemNota> itens = jdbc.query("""
                SELECT i.nf2_nrite, i.nf2_cdpro, pr.cp1_descr, i.nf2_quant, i.nf2_pruni,
                       i.nf2_desco, i.nf2_vlipi
                  FROM sci_fatnf2 i
                  LEFT JOIN sci_fatcp1 pr ON pr.cp1_cdemp = i.nf2_cpemp AND pr.cp1_codig = i.nf2_cdpro
                 WHERE i.nf2_seque = :seque
                 ORDER BY i.nf2_nrite
                """, Map.of("seque", sqnf1), (rs, i) -> {
            BigDecimal qt = rs.getBigDecimal("nf2_quant");
            BigDecimal pu = rs.getBigDecimal("nf2_pruni");
            BigDecimal desc = rs.getBigDecimal("nf2_desco");
            BigDecimal ipi = rs.getBigDecimal("nf2_vlipi");
            BigDecimal total = qt.multiply(pu).subtract(desc).add(ipi)
                    .setScale(2, java.math.RoundingMode.HALF_UP);
            return new ItemNota(
                    rs.getInt("nf2_nrite"),
                    rs.getLong("nf2_cdpro"),
                    trim(rs.getString("cp1_descr")),
                    qt, pu, desc, ipi, total);
        });

        List<NotaFiscal> notas = jdbc.query("""
                SELECT nf1_seque, nf1_notaf, nf1_serie, nf1_espec, nf1_dtemi, nf1_dtent, nf1_chnfe,
                       nf1_totpro, nf1_totdes, nf1_totipi, nf1_totfre, nf1_totout, nf1_obser
                  FROM sci_fatnf1
                 WHERE nf1_seque = :seque
                """, Map.of("seque", sqnf1), (rs, i) -> new NotaFiscal(
                rs.getLong("nf1_seque"),
                rs.getLong("nf1_notaf"),
                trim(rs.getString("nf1_serie")),
                trim(rs.getString("nf1_espec")),
                date(rs, "nf1_dtemi"),
                date(rs, "nf1_dtent"),
                trim(rs.getString("nf1_chnfe")),
                rs.getBigDecimal("nf1_totpro"),
                rs.getBigDecimal("nf1_totdes"),
                rs.getBigDecimal("nf1_totipi"),
                rs.getBigDecimal("nf1_totfre"),
                rs.getBigDecimal("nf1_totout"),
                trim(rs.getString("nf1_obser")),
                itens));
        return notas.stream().findFirst();
    }

    /**
     * Registra a decisão somente se a conta ainda estiver pendente e pertencer a um
     * departamento do usuário. Retorna o número de linhas alteradas (0 ou 1).
     */
    public int registrarDecisao(int cdemp, long seque, Departamentos deptos,
                                int situacao, String motivo, int usuario) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("situa", situacao)
                .addValue("motivo", motivo)
                .addValue("usuario", usuario)
                .addValue("cdemp", cdemp)
                .addValue("seque", seque);
        return jdbc.update("""
                UPDATE sci_fatpg1 p
                   SET pg1_situa = :situa,
                       pg1_alf05 = :motivo,
                       pg1_num05 = :usuario,
                       pg1_data5 = CURRENT_DATE
                 WHERE p.pg1_cdemp = :cdemp
                   AND p.pg1_seque = :seque
                   AND""" + PENDENTE + filtroDepto(deptos, params), params);
    }

    private static ContaResumo resumo(ResultSet rs) throws SQLException {
        BigDecimal cdcli = rs.getBigDecimal("pg1_cdcli");
        BigDecimal sqnf1 = rs.getBigDecimal("pg1_sqnf1");
        BigDecimal notaf = rs.getBigDecimal("nf1_notaf");
        return new ContaResumo(
                rs.getInt("pg1_cdemp"),
                rs.getLong("pg1_seque"),
                trim(rs.getString("pg1_titul")),
                date(rs, "pg1_dtemi"),
                date(rs, "pg1_dtven"),
                rs.getBigDecimal("pg1_valor"),
                cdcli == null ? null : cdcli.longValue(),
                trim(rs.getString("cl1_nomec")),
                rs.getLong("pg1_depto"),
                trim(rs.getString("dpt_descr")),
                rs.getLong("pg1_ccust"),
                trim(rs.getString("ccp_descr")),
                sqnf1 == null || notaf == null ? null : notaf.longValue(),
                trim(rs.getString("nf1_serie")));
    }

    private static LocalDate date(ResultSet rs, String col) throws SQLException {
        Date d = rs.getDate(col);
        if (d == null) {
            return null;
        }
        LocalDate ld = d.toLocalDate();
        return ld.equals(DATA_VAZIA) ? null : ld;
    }

    private static String trim(String s) {
        if (s == null) {
            return null;
        }
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
