{{ config(
    materialized='view'
) }}

WITH Reference AS (  
	SELECT
		DISTINCT (COALESCE(identifiant_de_la_mission, '') || COALESCE(statut_juridique_cd, '')) AS ref,
		identifiant_de_la_mission,
		statut_juridique_cd,
		statut_juridique_lb_corr
	FROM {{ ref('inspection_controle_PA__suites') }}
)
, Injonction AS (
    SELECT 
    	COALESCE(identifiant_de_la_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_de_la_mission,
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(nb_suite) AS injonction
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Injonction')
    GROUP BY 
    	identifiant_de_la_mission, 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Prescription AS (
    SELECT 
    	COALESCE(identifiant_de_la_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_de_la_mission,
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(nb_suite) AS prescription
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Prescription')
    GROUP BY 
    	identifiant_de_la_mission, 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Coercitif AS (
    SELECT 
    	COALESCE(identifiant_de_la_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_de_la_mission,
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(nb_suite) AS coercitif
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN (
    		'Injonction',
    		'Prescription')
    GROUP BY 
    	identifiant_de_la_mission, 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Recommandation AS (
    SELECT 
    	COALESCE(identifiant_de_la_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_de_la_mission,
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(nb_suite) AS recommandation
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Recommandation')
    GROUP BY 
    	identifiant_de_la_mission, 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, raw AS (
	SELECT
		Reference.ref,
		Reference.identifiant_de_la_mission,	
		Reference.statut_juridique_cd,	
		Reference.statut_juridique_lb_corr,
		Injonction.injonction,
		Prescription.prescription,
		Coercitif.coercitif,
		Recommandation.recommandation
	FROM Reference
	LEFT JOIN Injonction ON Reference.ref = Injonction.ref
	LEFT JOIN Prescription ON Reference.ref = Prescription.ref
	LEFT JOIN Coercitif ON Reference.ref = Coercitif.ref
	LEFT JOIN Recommandation ON Reference.ref = Recommandation.ref
)

SELECT 
	statut_juridique_lb_corr,
	COUNT(DISTINCT identifiant_de_la_mission) AS "Nombre total de missions d'I-C",
	SUM(injonction) AS "Nombre total d'injonctions",
	ROUND((CAST(SUM(injonction) AS NUMERIC) / NULLIF(CAST(COUNT(DISTINCT identifiant_de_la_mission) AS NUMERIC), 0)), 2) AS "Nombre moyen d'injonctions par mission d'I-C",
	SUM(prescription) AS "Nombre total de prescriptions",
	ROUND((CAST(SUM(prescription) AS NUMERIC) / NULLIF(CAST(COUNT(DISTINCT identifiant_de_la_mission) AS NUMERIC), 0)), 2) AS "Nombre moyen de ^prescriptions par mission d'I-C",
	SUM(coercitif) AS "Nombre total de suites coercitives",
	ROUND((CAST(SUM(coercitif) AS NUMERIC) / NULLIF(CAST(COUNT(DISTINCT identifiant_de_la_mission) AS NUMERIC), 0)), 2) AS "Nombre moyen de suites coercitives par mission d'I-C",
	SUM(recommandation) AS "Nombre total de recommandations",
	ROUND((CAST(SUM(recommandation) AS NUMERIC) / NULLIF(CAST(COUNT(DISTINCT identifiant_de_la_mission) AS NUMERIC), 0)), 2) AS "Nombre moyen de recommandations par mission d'I-C"
FROM raw
GROUP BY 
	statut_juridique_lb_corr