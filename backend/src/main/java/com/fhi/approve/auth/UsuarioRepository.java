package com.fhi.approve.auth;

import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class UsuarioRepository {

    private final NamedParameterJdbcTemplate jdbc;
    public UsuarioRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Usuario> findByCodigo(int codigo) {
        List<Usuario> list = jdbc.query("""
                SELECT sen_codig, sen_usuar, sen_senha, sen_dtval, sen_empre
                  FROM sci_presen
                 WHERE sen_codig = :codigo
                """, Map.of("codigo", codigo), (rs, i) -> {
            Date dtval = rs.getDate("sen_dtval");
            BigDecimal empre = rs.getBigDecimal("sen_empre");
            return new Usuario(
                    rs.getInt("sen_codig"),
                    trim(rs.getString("sen_usuar")),
                    trim(rs.getString("sen_senha")),
                    dtval == null ? null : dtval.toLocalDate(),
                    empre == null ? null : empre.intValue());
        });
        return list.stream().findFirst();
    }

    /** Departamentos vinculados ao usuário em sci_presen.sen_depto ("5;7", "9999" = todos). */
    public Departamentos findDepartamentos(int codigo) {
        List<String> list = jdbc.queryForList("""
                SELECT sen_depto
                  FROM sci_presen
                 WHERE sen_codig = :codigo
                """, Map.of("codigo", codigo), String.class);
        return list.isEmpty() ? Departamentos.NENHUM : Departamentos.parse(list.get(0));
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
