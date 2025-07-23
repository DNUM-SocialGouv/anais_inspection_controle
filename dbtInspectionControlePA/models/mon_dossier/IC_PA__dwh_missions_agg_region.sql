CREATE VIEW DWH_MISSIONS_AGG_region AS 
-- # SCRIPT des missions agrégées hors santé environnement
-- table lien entre code commune et codes département et région
WITH 
-- table qui compte les EHPAD selon la source FINESS 500 ACTUEL
compte_ehpad AS (
SELECT 
rg.REG_CD || rg.DEP_CD || t_finess_500.com_code as id_ref,
rg.REG_CD as reg_cd,
rg.REG_LB as reg_lb,
rg.DEP_CD as dep_cd,
rg.dep_lb as dep_lb,
t_finess_500.com_code as com_cd,
rg.COM_LB as com_lb,
finess,
rs
FROM TdBICFiness_500_20250207 t_finess_500
LEFT JOIN RefGeo_20250207 rg ON t_finess_500.com_code = rg.COM_CD 
--LEFT JOIN ref_insee_departement ON lien_communes.dep = ref_insee_departement.DEP 
--LEFT JOIN ref_insee_region ON ref_insee_departement.REG = ref_insee_region.reg_cd
)
-- table qui compte les ehpad contrôlés
, compte_ehpad_controles AS (
SELECT 
	CASE
		WHEN missions_real.CD_FINESS = """" THEN rr.REG
		WHEN rg.REG_CD IS NULL THEN ""NC""
		ELSE rg.REG_CD
	END || 
	CASE
		WHEN missions_real.CD_FINESS = """" THEN IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")
		WHEN rg.DEP_LB IS NULL THEN ""NC""
		ELSE rg.DEP_CD
	END || 
	IIF(t_finess.com_code IS NULL, ""NC"", t_finess.com_code)
as id_ref,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rr.REG
	WHEN rg.REG_CD IS NULL THEN ""NC""
	ELSE rg.REG_CD
END
as reg_cd,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rr.LIBELLE
	WHEN rg.REG_LB IS NULL THEN ""NC""
	ELSE rg.REG_LB
END
as reg_lb,
CASE
	WHEN missions_real.CD_FINESS = """" THEN IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")
	WHEN rg.DEP_LB IS NULL THEN ""NC""
	ELSE rg.DEP_CD
END
as dep_cd,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rd.LIBELLE
	WHEN rg.dep_lb IS NULL THEN ""NC""
	ELSE rg.dep_lb
END
as dep_lb,
IIF(t_finess.com_code IS NULL, ""NC"", t_finess.com_code) as com_cd,
IIF(rg.COM_CD  IS NULL, ""NC"", rg.COM_LB) as com_lb,
CD_FINESS
--FROM ODS_IC
FROM TdBICSiiceaMissionsReal_20250210 missions_real  
LEFT JOIN TdBICFiness_500_20250207 t_finess ON missions_real.CD_FINESS = t_finess.finess
LEFT JOIN RefGeo_20250207 rg ON t_finess.com_code = rg.COM_CD 
LEFT JOIN RefDepartements_20250207 rd ON (IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")) = rd.DEP 
LEFT JOIN RefRegions_20250207 rr ON rd.REG = rr.REG)
-- table qui compte le nombre de missions
, compte_missions AS (
SELECT 
	CASE
		WHEN missions_real.CD_FINESS = """" THEN rr.REG
		WHEN rg.REG_CD IS NULL THEN ""NC""
		ELSE rg.REG_CD
	END || 
	CASE
		WHEN missions_real.CD_FINESS = """" THEN IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")
		WHEN rg.DEP_LB IS NULL THEN ""NC""
		ELSE rg.DEP_CD
	END || 
	IIF(t_finess.com_code IS NULL, ""NC"", t_finess.com_code)
as id_ref,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rr.REG
	WHEN rg.REG_CD IS NULL THEN ""NC""
	ELSE rg.REG_CD
END
as reg_cd,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rr.LIBELLE
	WHEN rg.REG_LB IS NULL THEN ""NC""
	ELSE rg.REG_LB
END
as reg_lb,
CASE
	WHEN missions_real.CD_FINESS = """" THEN IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")
	WHEN rg.DEP_LB IS NULL THEN ""NC""
	ELSE rg.DEP_CD
END
as dep_cd,
CASE
	WHEN missions_real.CD_FINESS = """" THEN rd.LIBELLE
	WHEN rg.dep_lb IS NULL THEN ""NC""
	ELSE rg.dep_lb
END
as dep_lb,
IIF(t_finess.com_code IS NULL, ""NC"", t_finess.com_code) as com_cd,
IIF(rg.COM_CD  IS NULL, ""NC"", rg.COM_LB) as com_lb,
""Identifiant de la mission""
--FROM ODS_IC
FROM TdBICSiiceaMissionsReal_20250210 missions_real
LEFT JOIN TdBICFiness_500_20250207 t_finess ON missions_real.CD_FINESS = t_finess.finess
LEFT JOIN RefGeo_20250207 rg ON t_finess.com_code = rg.COM_CD 
LEFT JOIN RefDepartements_20250207 rd ON (IIF(LENGTH(missions_real.""Département"")=1, ""0"" || missions_real.""Département"", missions_real.""Département"")) = rd.DEP 
LEFT JOIN RefRegions_20250207 rr ON rd.REG = rr.REG)
-- table qui recense toutes les combinaisons id_ref possibles
, reference AS (
SELECT 
id_ref,
reg_cd,
reg_lb,
dep_cd,
dep_lb,
com_cd,
com_lb
FROM compte_ehpad
UNION 
SELECT 
id_ref,
reg_cd,
reg_lb,
dep_cd,
dep_lb,
com_cd,
com_lb
FROM compte_ehpad_controles
UNION 
SELECT 
id_ref,
reg_cd,
reg_lb,
dep_cd,
dep_lb,
com_cd,
com_lb
FROM compte_missions)
-- table qui croise les tables de compte_%
, communes AS (
SELECT 
reference.id_ref,
reference.reg_cd,
reference.reg_lb,
reference.dep_cd,
reference.dep_lb,
reference.com_cd,
reference.com_lb,
COUNT(DISTINCT finess) AS NB_EHPAD,
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_MISSION,
COUNT(DISTINCT CD_FINESS) AS NB_ETAB_CONTROLE,
(CAST(COUNT(DISTINCT CD_FINESS) AS FLOAT)/CAST(COUNT(DISTINCT finess) AS FLOAT))*100 AS NB_ETAB_CONTROLE_NB_EHPAD
FROM reference
LEFT JOIN compte_ehpad ON reference.id_ref = compte_ehpad.id_ref
LEFT JOIN compte_ehpad_controles ON reference.id_ref = compte_ehpad_controles.id_ref
LEFT JOIN compte_missions ON reference.id_ref = compte_missions.id_ref
GROUP BY 
reference.id_ref,
reference.reg_cd,
reference.reg_lb,
reference.dep_cd,
reference.dep_lb,
reference.com_cd,
reference.com_lb
)
-- table au niveau département
, departements AS (
SELECT 
reg_cd,
reg_lb,
dep_cd,
dep_lb,
SUM(NB_EHPAD) AS NB_EHPAD,
SUM(NB_MISSION) AS NB_MISSION,
SUM(NB_ETAB_CONTROLE) AS NB_ETAB_CONTROLE,
(CAST(SUM(NB_ETAB_CONTROLE) AS FLOAT)/CAST(SUM(NB_EHPAD) AS FLOAT))*100 AS NB_ETAB_CONTROLE_NB_EHPAD
FROM communes
GROUP BY 
reg_cd,
reg_lb,
dep_cd,
dep_lb
)
-- table au niveau régional
, regions AS (
SELECT 
reg_cd,
reg_lb,
SUM(NB_EHPAD) AS NB_EHPAD,
SUM(NB_MISSION) AS NB_MISSION,
SUM(NB_ETAB_CONTROLE) AS NB_ETAB_CONTROLE,
(CAST(SUM(NB_ETAB_CONTROLE) AS FLOAT)/CAST(SUM(NB_EHPAD) AS FLOAT))*100 AS NB_ETAB_CONTROLE_NB_EHPAD
FROM communes
GROUP BY 
reg_cd,
reg_lb
)
SELECT 
*
FROM regions"