package com.fhi.approve.contas;

import com.fhi.approve.contas.ContaDtos.ContaDetalhe;
import com.fhi.approve.contas.ContaDtos.ContaResumo;
import com.fhi.approve.contas.ContaDtos.DecisaoRequest;
import com.fhi.approve.contas.ContaDtos.DecisaoResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/contas")
public class ContaController {

    private final ContaService service;

    public ContaController(ContaService service) {
        this.service = service;
    }

    @GetMapping
    public List<ContaResumo> listar(@AuthenticationPrincipal Jwt jwt) {
        return service.listarPendentes(usuario(jwt));
    }

    @GetMapping("/{cdemp}/{seque}")
    public ContaDetalhe detalhe(@AuthenticationPrincipal Jwt jwt,
                                @PathVariable int cdemp, @PathVariable long seque) {
        return service.buscar(usuario(jwt), cdemp, seque);
    }

    @PostMapping("/{cdemp}/{seque}/aprovar")
    public DecisaoResponse aprovar(@AuthenticationPrincipal Jwt jwt,
                                   @PathVariable int cdemp, @PathVariable long seque,
                                   @Valid @RequestBody(required = false) DecisaoRequest body) {
        return service.aprovar(usuario(jwt), cdemp, seque, body == null ? null : body.motivo());
    }

    @PostMapping("/{cdemp}/{seque}/rejeitar")
    public DecisaoResponse rejeitar(@AuthenticationPrincipal Jwt jwt,
                                    @PathVariable int cdemp, @PathVariable long seque,
                                    @Valid @RequestBody DecisaoRequest body) {
        return service.rejeitar(usuario(jwt), cdemp, seque, body.motivo());
    }

    private static int usuario(Jwt jwt) {
        return Integer.parseInt(jwt.getSubject());
    }
}
