-- Subconjunto das tabelas do ERP usado pelo app
CREATE TABLE sci_presen (
  sen_codig numeric(5,0) PRIMARY KEY, sen_usuar varchar(30), sen_dtval date,
  sen_senha varchar(32) NOT NULL, sen_empre numeric(5,0), sen_depto varchar(200));
CREATE TABLE sci_deptop (dpt_codig numeric(10,0) PRIMARY KEY, dpt_descr varchar(30));
CREATE TABLE sci_ccusto (ccp_codig numeric(10,0) PRIMARY KEY, ccp_descr varchar(30));
CREATE TABLE sci_fatcl1 (cl1_cdemp numeric(5,0), cl1_codig numeric(8,0), cl1_nomec varchar(60),
  PRIMARY KEY (cl1_cdemp, cl1_codig));
CREATE TABLE sci_fatcp1 (cp1_cdemp numeric(5,0), cp1_codig numeric(13,0), cp1_descr varchar(60),
  PRIMARY KEY (cp1_cdemp, cp1_codig));
CREATE TABLE sci_fatnf1 (
  nf1_seque numeric(18,0) PRIMARY KEY, nf1_notaf numeric(9,0) DEFAULT 0 NOT NULL,
  nf1_serie varchar(3) DEFAULT ' ' NOT NULL, nf1_espec varchar(5) DEFAULT ' ' NOT NULL,
  nf1_dtemi date DEFAULT DATE '1800-01-01' NOT NULL, nf1_dtent date DEFAULT DATE '1800-01-01' NOT NULL,
  nf1_chnfe varchar(44) DEFAULT ' ' NOT NULL,
  nf1_totpro numeric(13,2) DEFAULT 0 NOT NULL, nf1_totdes numeric(13,2) DEFAULT 0 NOT NULL,
  nf1_totipi numeric(13,2) DEFAULT 0 NOT NULL, nf1_totfre numeric(13,2) DEFAULT 0 NOT NULL,
  nf1_totout numeric(13,2) DEFAULT 0 NOT NULL, nf1_obser varchar(300));
CREATE TABLE sci_fatnf2 (
  nf2_seque numeric(18,0), nf2_nrite numeric(5,0), nf2_cpemp numeric(5,0) DEFAULT 0 NOT NULL,
  nf2_cdpro numeric(13,0) DEFAULT 0 NOT NULL, nf2_quant numeric(10,3) DEFAULT 0 NOT NULL,
  nf2_pruni numeric(13,5) DEFAULT 0 NOT NULL, nf2_desco numeric(13,2) DEFAULT 0 NOT NULL,
  nf2_vlipi numeric(13,2) DEFAULT 0 NOT NULL, PRIMARY KEY (nf2_seque, nf2_nrite));
CREATE TABLE sci_fatpg1 (
  pg1_cdemp numeric(5,0), pg1_seque numeric(18,0), pg1_clemp numeric(5,0) DEFAULT 0 NOT NULL,
  pg1_cdcli numeric(8,0) DEFAULT 0, pg1_titul varchar(15) DEFAULT ' ' NOT NULL,
  pg1_dtemi date DEFAULT DATE '1800-01-01' NOT NULL, pg1_tpven varchar(12) DEFAULT ' ' NOT NULL,
  pg1_dtven date DEFAULT DATE '1800-01-01' NOT NULL, pg1_judia numeric(18,2) DEFAULT 0 NOT NULL,
  pg1_vldes numeric(18,2) DEFAULT 0 NOT NULL, pg1_valor numeric(18,2) DEFAULT 0 NOT NULL,
  pg1_vlror numeric(18,2) DEFAULT 0 NOT NULL, pg1_depto numeric(10,0) DEFAULT 0 NOT NULL,
  pg1_ccust numeric(10,0) DEFAULT 0 NOT NULL, pg1_nubco varchar(47) DEFAULT ' ' NOT NULL,
  pg1_dtlan date DEFAULT DATE '1800-01-01' NOT NULL, pg1_dtpag date DEFAULT DATE '1800-01-01' NOT NULL,
  pg1_obser varchar(100) DEFAULT ' ' NOT NULL, pg1_situa numeric(1,0) DEFAULT 0 NOT NULL,
  pg1_sqnf1 numeric(18,0), pg1_alf05 varchar(100), pg1_num05 numeric(18,0) DEFAULT 0 NOT NULL,
  pg1_data5 date DEFAULT DATE '1800-01-01' NOT NULL,
  PRIMARY KEY (pg1_cdemp, pg1_seque));
