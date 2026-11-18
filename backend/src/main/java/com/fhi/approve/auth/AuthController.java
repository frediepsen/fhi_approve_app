package com.fhi.approve.auth;

import com.fhi.approve.common.ApiException;
import com.fhi.approve.config.AppProperties;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.util.DigestUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    public record LoginRequest(@NotNull Integer codigo, @NotBlank String senha) {
    }

    public record LoginResponse(String token, Instant expiraEm, int codigo, String nome,
                                List<Long> departamentos, boolean todosDepartamentos) {
    }

    private final UsuarioRepository usuarios;
    private final JwtEncoder encoder;
    private final AppProperties props;

    public AuthController(UsuarioRepository usuarios, JwtEncoder encoder, AppProperties props) {
        this.usuarios = usuarios;
        this.encoder = encoder;
        this.props = props;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest req) {
        Usuario u = usuarios.findByCodigo(req.codigo())
                .filter(x -> senhaConfere(req.senha(), x.senhaMd5()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Usuário ou senha inválidos"));

//        if (u.validade() != null && u.validade().isBefore(LocalDate.now())) {
//            throw new ApiException(HttpStatus.FORBIDDEN, "Senha expirada");
//        }

        Departamentos deptos = usuarios.findDepartamentos(u.codigo());
        if (deptos.vazio()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Usuário sem departamentos vinculados para aprovação");
        }

        Instant now = Instant.now();
        Instant exp = now.plus(props.jwt().expirationHours(), ChronoUnit.HOURS);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("fhi-approve")
                .subject(String.valueOf(u.codigo()))
                .issuedAt(now)
                .expiresAt(exp)
                .claim("nome", u.nome() == null ? "" : u.nome())
                .build();
        String token = encoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();

        return new LoginResponse(token, exp, u.codigo(), u.nome(), List.copyOf(deptos.codigos()), deptos.todos());
    }

    static boolean senhaConfere(String senha, String md5Banco) {
        if (md5Banco == null) {
            return false;
        }
        String md5 = DigestUtils.md5DigestAsHex(senha.getBytes(StandardCharsets.UTF_8));
        // comparação em tempo constante; hash do banco pode estar em maiúsculas
        return MessageDigest.isEqual(
                md5.getBytes(StandardCharsets.US_ASCII),
                md5Banco.toLowerCase().getBytes(StandardCharsets.US_ASCII));
    }
}
