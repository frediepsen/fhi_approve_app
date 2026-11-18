package com.fhi.approve.contas;

import com.fhi.approve.auth.Departamentos;
import com.fhi.approve.auth.UsuarioRepository;
import com.fhi.approve.common.ApiException;
import com.fhi.approve.contas.ContaDtos.ContaDetalhe;
import com.fhi.approve.contas.ContaDtos.ContaResumo;
import com.fhi.approve.contas.ContaDtos.DecisaoResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ContaService {

    private final ContaRepository contas;
    private final UsuarioRepository usuarios;

    public ContaService(ContaRepository contas, UsuarioRepository usuarios) {
        this.contas = contas;
        this.usuarios = usuarios;
    }

    public List<ContaResumo> listarPendentes(int usuario) {
        Departamentos deptos = usuarios.findDepartamentos(usuario);
        return deptos.vazio() ? List.of() : contas.listarPendentes(deptos);
    }

    public ContaDetalhe buscar(int usuario, int cdemp, long seque) {
        Departamentos deptos = departamentosObrigatorios(usuario);
        return contas.buscar(cdemp, seque, deptos)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Conta não encontrada"));
    }

    @Transactional
    public DecisaoResponse aprovar(int usuario, int cdemp, long seque, String observacao) {
        return decidir(usuario, cdemp, seque, ContaDtos.APROVADO, normalizar(observacao));
    }

    @Transactional
    public DecisaoResponse rejeitar(int usuario, int cdemp, long seque, String motivo) {
        String m = normalizar(motivo);
        if (m == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Informe o motivo da rejeição");
        }
        return decidir(usuario, cdemp, seque, ContaDtos.REJEITADO, m);
    }

    private DecisaoResponse decidir(int usuario, int cdemp, long seque, int situacao, String motivo) {
        Departamentos deptos = departamentosObrigatorios(usuario);
        int n = contas.registrarDecisao(cdemp, seque, deptos, situacao, motivo, usuario);
        if (n == 1) {
            return new DecisaoResponse(cdemp, seque, situacao);
        }
        // Nada alterado: ou não existe/não é do usuário, ou já foi decidida/paga.
        if (contas.buscar(cdemp, seque, deptos).isEmpty()) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Conta não encontrada");
        }
        throw new ApiException(HttpStatus.CONFLICT, "Conta não está mais pendente de aprovação");
    }

    private Departamentos departamentosObrigatorios(int usuario) {
        Departamentos deptos = usuarios.findDepartamentos(usuario);
        if (deptos.vazio()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Usuário sem departamentos vinculados para aprovação");
        }
        return deptos;
    }

    private static String normalizar(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        return s.trim();
    }
}
