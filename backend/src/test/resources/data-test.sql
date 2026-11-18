-- usuário 10 / senha "1234" (md5 81dc9bdb52d04dc20036dbd8313ed055, gravado em maiúsculas)
INSERT INTO sci_presen VALUES (10, 'MARIA', NULL, '81DC9BDB52D04DC20036DBD8313ED055', 1, '5;7');
-- usuário 11 / senha "1234", sem departamentos
INSERT INTO sci_presen VALUES (11, 'JOAO', NULL, '81dc9bdb52d04dc20036dbd8313ed055', 1, NULL);
-- usuário 12 / senha "1234", expirado
INSERT INTO sci_presen VALUES (12, 'ANA', DATE '2000-01-01', '81dc9bdb52d04dc20036dbd8313ed055', 1, '5');
-- usuário 13 / senha "1234", todos os departamentos
INSERT INTO sci_presen VALUES (13, 'PEDRO', NULL, '81dc9bdb52d04dc20036dbd8313ed055', 1, '9999');

INSERT INTO sci_deptop VALUES (5, 'COMPRAS'), (7, 'TI'), (9, 'RH');
INSERT INTO sci_ccusto VALUES (100, 'ADMINISTRATIVO');
INSERT INTO sci_fatcl1 VALUES (1, 500, 'FORNECEDOR XPTO LTDA');
INSERT INTO sci_fatcp1 VALUES (1, 42, 'PARAFUSO 10MM');

INSERT INTO sci_fatnf1 (nf1_seque, nf1_notaf, nf1_serie, nf1_dtemi, nf1_totpro)
VALUES (900, 12345, '1', DATE '2026-10-01', 150.00);
INSERT INTO sci_fatnf2 (nf2_seque, nf2_nrite, nf2_cpemp, nf2_cdpro, nf2_quant, nf2_pruni, nf2_desco, nf2_vlipi)
VALUES (900, 1, 1, 42, 10, 15, 0, 0);

-- 1: pendente, depto 5, com NF
INSERT INTO sci_fatpg1 (pg1_cdemp, pg1_seque, pg1_clemp, pg1_cdcli, pg1_titul, pg1_dtven, pg1_valor, pg1_depto, pg1_ccust, pg1_sqnf1)
VALUES (1, 1, 1, 500, 'TIT-1', DATE '2026-11-20', 150.00, 5, 100, 900);
-- 2: pendente, depto 7 (outra empresa)
INSERT INTO sci_fatpg1 (pg1_cdemp, pg1_seque, pg1_titul, pg1_dtven, pg1_valor, pg1_depto)
VALUES (2, 2, 'TIT-2', DATE '2026-11-15', 80.00, 7);
-- 3: depto 9 (não pertence ao usuário)
INSERT INTO sci_fatpg1 (pg1_cdemp, pg1_seque, pg1_titul, pg1_valor, pg1_depto)
VALUES (1, 3, 'TIT-3', 10.00, 9);
-- 4: já paga
INSERT INTO sci_fatpg1 (pg1_cdemp, pg1_seque, pg1_titul, pg1_valor, pg1_depto, pg1_dtpag)
VALUES (1, 4, 'TIT-4', 10.00, 5, DATE '2026-10-10');
-- 5: já aprovada
INSERT INTO sci_fatpg1 (pg1_cdemp, pg1_seque, pg1_titul, pg1_valor, pg1_depto, pg1_situa)
VALUES (1, 5, 'TIT-5', 10.00, 5, 1);
