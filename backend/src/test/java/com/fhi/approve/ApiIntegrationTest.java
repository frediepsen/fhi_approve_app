package com.fhi.approve;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
class ApiIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;

    private String login(int codigo, String senha) throws Exception {
        String body = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("codigo", codigo, "senha", senha))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode n = json.readTree(body);
        return "Bearer " + n.get("token").asText();
    }

    private void loginStatus(int codigo, String senha, int expected) throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("codigo", codigo, "senha", senha))))
                .andExpect(status().is(expected));
    }

    @Test
    void loginValidaSenhaValidadeEDepartamentos() throws Exception {
        loginStatus(10, "errada", 401);
        loginStatus(99, "1234", 401);
        loginStatus(11, "1234", 403); // sen_depto vazio
        loginStatus(12, "1234", 403); // expirado
        login(10, "1234");
    }

    @Test
    void semTokenRetorna401() throws Exception {
        mvc.perform(get("/api/contas")).andExpect(status().isUnauthorized());
    }

    @Test
    void listaApenasPendentesDosDepartamentos() throws Exception {
        String token = login(10, "1234");
        mvc.perform(get("/api/contas").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].sequencia").value(2)) // vence antes
                .andExpect(jsonPath("$[1].sequencia").value(1))
                .andExpect(jsonPath("$[1].fornecedorNome").value("FORNECEDOR XPTO LTDA"))
                .andExpect(jsonPath("$[1].departamentoDescricao").value("COMPRAS"))
                .andExpect(jsonPath("$[1].centroCustoDescricao").value("ADMINISTRATIVO"))
                .andExpect(jsonPath("$[1].notaFiscal").value(12345))
                .andExpect(jsonPath("$[0].emissao").value(nullValue()));
    }

    @Test
    void detalheTrazNotaEItens() throws Exception {
        String token = login(10, "1234");
        mvc.perform(get("/api/contas/1/1").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nota.numero").value(12345))
                .andExpect(jsonPath("$.nota.itens", hasSize(1)))
                .andExpect(jsonPath("$.nota.itens[0].descricao").value("PARAFUSO 10MM"))
                .andExpect(jsonPath("$.nota.itens[0].total").value(150.00));
        mvc.perform(get("/api/contas/1/3").header("Authorization", token))
                .andExpect(status().isNotFound());
    }

    @Test
    void aprovarGravaSituacaoEAuditoria() throws Exception {
        String token = login(10, "1234");
        mvc.perform(post("/api/contas/1/1/aprovar").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.situacao").value(1));

        Map<String, Object> row = jdbc.queryForMap(
                "SELECT pg1_situa, pg1_num05, pg1_alf05, pg1_data5 FROM sci_fatpg1 WHERE pg1_cdemp=1 AND pg1_seque=1");
        assertThat(((Number) row.get("pg1_situa")).intValue()).isEqualTo(1);
        assertThat(((Number) row.get("pg1_num05")).intValue()).isEqualTo(10);
        assertThat(row.get("pg1_alf05")).isNull();
        assertThat(row.get("pg1_data5").toString()).isNotEqualTo("1800-01-01");

        // segunda decisão -> conflito
        mvc.perform(post("/api/contas/1/1/rejeitar").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motivo\":\"x\"}"))
                .andExpect(status().isConflict());
    }

    @Test
    void rejeitarExigeMotivo() throws Exception {
        String token = login(10, "1234");
        mvc.perform(post("/api/contas/2/2/rejeitar").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motivo\":\"  \"}"))
                .andExpect(status().isBadRequest());
        mvc.perform(post("/api/contas/2/2/rejeitar").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"motivo\":\"Valor divergente\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.situacao").value(2));
        assertThat(jdbc.queryForObject(
                "SELECT pg1_alf05 FROM sci_fatpg1 WHERE pg1_cdemp=2 AND pg1_seque=2", String.class))
                .isEqualTo("Valor divergente");
    }

    @Test
    void departamento9999VeTodos() throws Exception {
        String token = login(13, "1234");
        mvc.perform(get("/api/contas").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)));
        mvc.perform(post("/api/contas/1/3/aprovar").header("Authorization", token))
                .andExpect(status().isOk());
        assertThat(jdbc.queryForObject(
                "SELECT pg1_num05 FROM sci_fatpg1 WHERE pg1_cdemp=1 AND pg1_seque=3", Integer.class))
                .isEqualTo(13);
    }

    @Test
    void naoDecideContaDeOutroDepartamentoOuJaPaga() throws Exception {
        String token = login(10, "1234");
        mvc.perform(post("/api/contas/1/3/aprovar").header("Authorization", token))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/contas/1/4/aprovar").header("Authorization", token))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/contas/1/5/aprovar").header("Authorization", token))
                .andExpect(status().isConflict());
    }
}
