package com.fhi.approve.auth;

import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Departamentos que o usuário pode aprovar, lidos de sci_presen.sen_depto
 * (códigos separados por ';'). O código {@value #TODOS_CODIGO} libera todos.
 */
public record Departamentos(boolean todos, Set<Long> codigos) {

    public static final long TODOS_CODIGO = 9999;

    public static final Departamentos NENHUM = new Departamentos(false, Set.of());

    public Departamentos {
        codigos = Set.copyOf(codigos);
    }

    public boolean vazio() {
        return !todos && codigos.isEmpty();
    }

    public static Departamentos parse(String senDepto) {
        if (senDepto == null || senDepto.isBlank()) {
            return NENHUM;
        }
        Set<Long> codigos = new LinkedHashSet<>();
        for (String parte : senDepto.split(";")) {
            String p = parte.trim();
            if (p.isEmpty()) {
                continue;
            }
            long codigo;
            try {
                codigo = Long.parseLong(p);
            } catch (NumberFormatException e) {
                continue;
            }
            if (codigo == TODOS_CODIGO) {
                return new Departamentos(true, Set.of());
            }
            if (codigo != 0) {
                codigos.add(codigo);
            }
        }
        return new Departamentos(false, codigos);
    }
}
