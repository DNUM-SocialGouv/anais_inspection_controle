CREATE VIEW DWH_MISSIONS_PROG AS 
-- # SCRIPT des missions programmées
-- table lien entre code commune et codes département et région
WITH 
-- table qui croise ODS_IC avec les ref geo / cibles et fait les autres transfo
missions_prev_complet AS (
SELECT
CASE
	WHEN missions_prev.CD_FINESS = """" THEN rr.REG
	WHEN rg.REG_CD IS NULL THEN ""NC""
	ELSE rg.REG_CD
END
as reg_cd,
CASE
	WHEN missions_prev.CD_FINESS = """" THEN rr.LIBELLE
	WHEN rg.REG_LB IS NULL THEN ""NC""
	ELSE rg.REG_LB
END
as reg_lb,
CASE
	WHEN missions_prev.CD_FINESS = """" THEN IIF(LENGTH(missions_prev.""Département"")=1, ""0"" || missions_prev.""Département"", missions_prev.""Département"")
	WHEN rg.DEP_LB IS NULL THEN ""NC""
	ELSE rg.DEP_CD
END
as dep_cd,
CASE
	WHEN missions_prev.CD_FINESS = """" THEN rd.LIBELLE
	WHEN rg.dep_lb IS NULL THEN ""NC""
	ELSE rg.dep_lb
END
as dep_lb,
IIF(t_finess.com_code IS NULL, ""NC"", t_finess.com_code) as com_cd,
IIF(rg.COM_CD  IS NULL, ""NC"", rg.COM_LB) as com_lb,
missions_prev.CD_FINESS AS finess_cd,
missions_prev.Cible,
missions_prev.""Identifiant de la mission"",
t_finess.statut_jur_niv2_code AS statut_juridique_cd,
IIF(t_finess.statut_jur_niv2_lib = '', ""NC"", t_finess.statut_jur_niv2_lib) AS statut_juridique_lb,
--missions_prev.RAISON_SOCIALE_SIREN AS groupe,
missions_prev.""Type de mission"" AS type_de_mission,
--CASE 
--	WHEN missions_prev.""Type de mission"" = ""contrôle sur pièces"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Contrôle sur pièces"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Contrôle sur pièces EHPAD"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""EHPAD Contrôle sur pièces"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Ctrl_sur_Pièces"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Inspection"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Inspection Technique"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""inspection"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Evaluation"" THEN ""Evaluation""
--	WHEN missions_prev.""Type de mission"" = ""Contrôle"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Enquête administrative"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Visites de conformité"" THEN ""Visites de conformité""
--	WHEN missions_prev.""Type de mission"" = ""Contrôle sur place / Visite de vérification"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Inspection_SE"" THEN ""Inspection santé-environnement""
--	WHEN missions_prev.""Type de mission"" = ""Inspection_prgm21"" THEN ""Contrôle sur place""
--    WHEN missions_prev.""Type de mission"" = ""Inspection_prgm23"" THEN ""Contrôle sur place""
--    WHEN missions_prev.""Type de mission"" = ""Inspection_prgm24"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""contrôle"" THEN ""Contrôle sur place""
--	WHEN missions_prev.""Type de mission"" = ""Contrôle sur pièces (Avec contradictoire)"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Controle sur pièces contradictoire"" THEN ""Contrôle sur pièces""
--	WHEN missions_prev.""Type de mission"" = ""Suites d'inspection"" THEN ""Contrôle sur place""
--	ELSE ""NC""
--END
modalite_d_investigation AS CTRL_PL_PI,
--group_mottif_sante_env.group_hsa_sa,
--IIF(group_mottif_sante_env.group_hsa_sa = 'motif_hsa' AND ODS_IC.""Type de mission"" != 'Evaluation' AND ODS_IC.""Type de mission"" != 'Visites de conformité',""Hors santé-environnement"",""Santé-environnement"") AS filtre,
missions_prev.""Statut de la mission"",
missions_prev.""Date provisoire """"Visite"""""",
--groupe_diamant.GROUPE AS GROUPE_2,
sa_cibles.""Groupe de cibles"" AS groupe_siicea,
IIF(missions_prev.""Type de planification"" = 'Inopiné', 'Programmé', missions_prev.""Type de planification"") AS ""Type de planification"",
""Mission conjointe avec 1"",
""Mission conjointe avec 2"",
CASE 
	WHEN (""Mission conjointe avec 1"" LIKE ""%Conseil départemental%"" OR ""Mission conjointe avec 1"" LIKE ""%Département%"" OR ""Mission conjointe avec 2"" LIKE ""%Conseil départemental%"") THEN ""ARS / CD""
	WHEN ""Mission conjointe avec 1"" = '' OR ""Mission conjointe avec 1"" = 'Non' THEN ""Non conjointe""
	ELSE ""ARS + autre administration""
END AS mission_conjointe,
IIF(""Modalité de la mission""='', 'NC', ""Modalité de la mission"") AS ""Modalité de la mission""
--FROM ODS_IC 
FROM TdBICSiiceaMissionsprog_20250210 missions_prev
LEFT JOIN TdBICFiness_500_20250207 t_finess ON missions_prev.CD_FINESS = t_finess.finess
LEFT JOIN RefGeo_20250207 rg ON t_finess.com_code = rg.COM_CD 
LEFT JOIN RefDepartements_20250207 rd ON (IIF(LENGTH(missions_prev.""Département"")=1, ""0"" || missions_prev.""Département"", missions_prev.""Département"")) = rd.DEP 
LEFT JOIN RefRegions_20250207 rr ON rd.REG = rr.REG
--LEFT JOIN group_mottif_sante_env ON ODS_IC.""Identifiant de la mission"" = group_mottif_sante_env.""Identifiant de la mission""
--LEFT JOIN groupe_diamant ON ODS_IC.CD_FINESS = groupe_diamant.FINESS
LEFT JOIN TdBICSiiceaCibles_20250210 sa_cibles ON missions_prev.CD_FINESS = sa_cibles.FINESS 
--WHERE ""Type de mission"" NOT IN (
--'Evaluation',
--'Visites de conformité', 
--'Audit franco-wallon')
),
dwh AS (
SELECT 
reg_cd,
reg_lb,
dep_cd,
dep_lb,
com_cd,
com_lb,
finess_cd,
Cible,
statut_juridique_cd,
statut_juridique_lb,
"""" AS groupe,
type_de_mission,
CTRL_PL_PI,
"""" AS filtre,
""Statut de la mission"",
""Date provisoire """"Visite"""""",
"""" AS GROUPE_2,
groupe_siicea,
""Type de planification"",
mission_conjointe,
""Modalité de la mission"",
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_MISSION
FROM missions_prev_complet
GROUP BY 
reg_cd,
reg_lb,
dep_cd,
dep_lb,
com_cd,
com_lb,
finess_cd,
Cible,
statut_juridique_cd,
statut_juridique_lb,
groupe,
type_de_mission,
CTRL_PL_PI,
filtre,
""Statut de la mission"",
""Date provisoire """"Visite"""""",
GROUPE_2,
groupe_siicea,
""Type de planification"",
mission_conjointe,
""Modalité de la mission""
)
SELECT 
*
FROM dwh"