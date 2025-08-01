{{ config(
    materialized='view'
) }}


-- # SCRIPT des missions agrégées hors santé environnement
-- table lien entre code commune et codes département et région
-- table qui compte les EHPAD selon la source FINESS 500 ACTUEL
WITH compte_ehpad AS (
	SELECT 
		rg.reg_cd || rg.dep_cd || t_finess_500.com_code as id_ref,
		rg.reg_cd as reg_cd,
		rg.reg_lb as reg_lb,
		rg.dep_cd as dep_cd,
		rg.dep_lb as dep_lb,
		t_finess_500.com_code as com_cd,
		rg.com_lb as com_lb,
		finess,
		rs
	FROM {{ ref('staging__tdb_ic_finess_500') }} t_finess_500
	LEFT JOIN {{ ref('staging__ref_geo') }} rg ON t_finess_500.com_code = rg.com_cd 
	--LEFT JOIN ref_insee_departement ON lien_communes.dep = ref_insee_departement.dep 
	--LEFT JOIN ref_insee_region ON ref_insee_departement.reg = ref_insee_region.reg_cd
)
-- table qui compte les ehpad contrôlés
, compte_ehpad_controles AS (
	SELECT 
		CASE
			WHEN m.finess_geographique = '' THEN rr.reg
			WHEN rg.reg_cd IS NULL THEN 'NC'
			ELSE rg.reg_cd
		END || 
		CASE
			WHEN m.finess_geographique = '' THEN {{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_cd
		END || 
		{{ iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }}
		as id_ref,
		CASE
			WHEN m.finess_geographique = '' THEN rr.reg
			WHEN rg.reg_cd IS NULL THEN 'NC'
			ELSE rg.reg_cd
		END
		as reg_cd,
		CASE
			WHEN m.finess_geographique = '' THEN rr.libelle
			WHEN rg.reg_lb IS NULL THEN 'NC'
			ELSE rg.reg_lb
		END
		as reg_lb,
		CASE
			WHEN m.finess_geographique = '' THEN {{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_cd
		END
		as dep_cd,
		CASE
			WHEN m.finess_geographique = '' THEN rd.libelle
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_lb
		END
		as dep_lb,
		{{ iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }} as com_cd,
		{{ iif_replacement("rg.com_cd  IS NULL", "'NC'", "rg.com_lb") }} as com_lb,
		finess_geographique
	--FROM ODS_IC
	FROM {{ ref('staging__sa_siicea_missions_real') }} m  
	LEFT JOIN {{ ref('staging__tdb_ic_finess_500') }} t_finess ON m.finess_geographique = t_finess.finess
	LEFT JOIN {{ ref('staging__ref_geo') }} rg ON t_finess.com_code = rg.com_cd 
	LEFT JOIN {{ ref('staging__ref_departements') }} rd ON ({{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}) = rd.dep 
	LEFT JOIN {{ ref('staging__ref_regions') }} rr ON rd.reg = rr.reg
)
-- table qui compte le nombre de missions
, compte_missions AS (
	SELECT 
		CASE
			WHEN m.finess_geographique = '' THEN rr.reg
			WHEN rg.reg_cd IS NULL THEN 'NC'
			ELSE rg.reg_cd
		END || 
		CASE
			WHEN m.finess_geographique = '' THEN {{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_cd
		END || 
		{{ iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }}
		as id_ref,
		CASE
			WHEN m.finess_geographique = '' THEN rr.reg
			WHEN rg.reg_cd IS NULL THEN 'NC'
			ELSE rg.reg_cd
		END
		as reg_cd,
		CASE
			WHEN m.finess_geographique = '' THEN rr.libelle
			WHEN rg.reg_lb IS NULL THEN 'NC'
			ELSE rg.reg_lb
		END
		as reg_lb,
		CASE
			WHEN m.finess_geographique = '' THEN {{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_cd
		END
		as dep_cd,
		CASE
			WHEN m.finess_geographique = '' THEN rd.libelle
			WHEN rg.dep_lb IS NULL THEN 'NC'
			ELSE rg.dep_lb
		END
		as dep_lb,
		{{ iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }} as com_cd,
		{{ iif_replacement("rg.com_cd  IS NULL", "'NC'", "rg.com_lb") }} as com_lb,
	identifiant_de_la_mission
	--FROM ODS_IC
	FROM {{ ref('staging__sa_siicea_missions_real') }} m
	LEFT JOIN {{ ref('staging__tdb_ic_finess_500') }} t_finess ON m.finess_geographique = t_finess.finess
	LEFT JOIN {{ ref('staging__ref_geo') }} rg ON t_finess.com_code = rg.com_cd 
	LEFT JOIN {{ ref('staging__ref_departements') }} rd ON ({{ iif_replacement("LENGTH(m.departement)=1", "'0' || m.departement", "m.departement") }}) = rd.dep 
	LEFT JOIN {{ ref('staging__ref_regions') }} rr ON rd.reg = rr.reg
)
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
	FROM compte_missions
)
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
		COUNT(DISTINCT finess) AS nb_ehpad,
		COUNT(DISTINCT identifiant_de_la_mission) AS nb_mission,
		COUNT(DISTINCT finess_geographique) AS nb_etab_controle,
		(CAST(COUNT(DISTINCT finess_geographique) AS FLOAT)/NULLIF(CAST(COUNT(DISTINCT finess) AS FLOAT), 0))*100 AS nb_etab_controle_nb_ehpad
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
		SUM(nb_ehpad) AS nb_ehpad,
		SUM(nb_mission) AS nb_mission,
		SUM(nb_etab_controle) AS nb_etab_controle,
		(CAST(SUM(nb_etab_controle) AS FLOAT)/NULLIF(CAST(SUM(nb_ehpad) AS FLOAT), 0))*100 AS nb_etab_controle_nb_ehpad
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
		SUM(nb_ehpad) AS nb_ehpad,
		SUM(nb_mission) AS nb_mission,
		SUM(nb_etab_controle) AS nb_etab_controle,
		(CAST(SUM(nb_etab_controle) AS FLOAT)/NULLIF(CAST(SUM(nb_ehpad) AS FLOAT), 0))*100 AS nb_etab_controle_nb_ehpad
	FROM communes
	GROUP BY 
		reg_cd,
		reg_lb
)
, nat AS (
	SELECT 
		SUM(nb_ehpad) AS nb_ehpad,
		SUM(nb_mission) AS nb_mission,
		SUM(nb_etab_controle) AS nb_etab_controle,
		(CAST(SUM(nb_etab_controle) AS FLOAT)/NULLIF(CAST(SUM(nb_ehpad) AS FLOAT), 0))*100 AS "Taux d'EHPAD différents inspectés au moins une fois"
	FROM communes
)

SELECT 
	*
FROM nat