# fhi_approve — Aprovação de contas a pagar

- `backend/` — Spring Boot 3.5 (Java 21), JDBC puro sobre o PostgreSQL do ERP, JWT HS256.
- `app/` — Flutter (Android, iOS, Web).

## Regras de negócio

| Item | Regra |
|---|---|
| Login | `sci_presen.sen_codig` + `md5(senha)` comparado com `sen_senha` (sem diferenciar maiúsculas). Bloqueia se `sen_dtval` < hoje. |
| Departamentos do usuário | `sci_presen.sen_depto`: códigos de `sci_deptop` separados por `;` (ex.: `5;7`). `9999` = todos os departamentos. Vazio → login recusado. |
| Contas listadas | `sci_fatpg1` com `pg1_depto` nos departamentos do usuário, `pg1_situa = 0` e `pg1_dtpag = 1800-01-01` (não paga). Todas as empresas. |
| Aprovar | `pg1_situa = 1`, `pg1_alf05` = observação (opcional), `pg1_num05` = usuário, `pg1_data5` = data. |
| Rejeitar | `pg1_situa = 2`, `pg1_alf05` = motivo (**obrigatório**, até 100 caracteres), `pg1_num05`, `pg1_data5`. |
| Reversão | Não permitida. O UPDATE só altera conta ainda pendente → 409 se já decidida/paga. |

Os departamentos são relidos a cada requisição, então alterações em `sen_depto` valem na hora.

## Endpoints

| Método | Caminho | Descrição |
|---|---|---|
| POST | `/api/auth/login` | `{ "codigo": 10, "senha": "..." }` → `{ token, expiraEm, codigo, nome, departamentos, todosDepartamentos }` |
| GET | `/api/contas` | Lista pendentes (ordenadas por vencimento) |
| GET | `/api/contas/{cdemp}/{seque}` | Detalhe + centro de custo, departamento, NF (`sci_fatnf1`) e itens (`sci_fatnf2` + `sci_fatcp1.cp1_descr`) |
| POST | `/api/contas/{cdemp}/{seque}/aprovar` | Corpo opcional `{ "motivo": "obs" }` |
| POST | `/api/contas/{cdemp}/{seque}/rejeitar` | `{ "motivo": "..." }` |

Todas exceto login exigem `Authorization: Bearer <token>`. Erros retornam `{ "erro": "mensagem" }`.

## Rodando o backend

```bash
cd backend
export DB_URL=jdbc:postgresql://192.168.25.30:5432/porto_figueira  # já é o padrão
export DB_USER=usuario
export DB_PASSWORD=senha
export JWT_SECRET='uma-chave-com-pelo-menos-32-caracteres'
# opcionais: PORT=8080 JWT_EXPIRATION_HOURS=8 CORS_ORIGINS=*
./gradlew bootRun
```

Testes (H2 em modo PostgreSQL, não precisa do banco real): `./gradlew test`.

## Rodando o app

```bash
cd app
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

No emulador Android use `http://10.0.2.2:8080`. Para HTTP sem TLS em release, Android exige
`android:usesCleartextTraffic="true"` e iOS exige exceção de ATS — prefira servir a API via HTTPS.
# fhi_approve_app
