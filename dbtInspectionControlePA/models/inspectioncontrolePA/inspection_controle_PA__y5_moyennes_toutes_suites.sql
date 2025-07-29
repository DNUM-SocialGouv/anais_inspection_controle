{{ config(
    materialized='view'
) }}


WITH Reference AS (  
	SELECT
		DISTINCT (COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '')) AS ref,
		identifiant_mission
	FROM {{ ref('inspection_controle_PA__suites') }}
)
, Injonction AS (
    SELECT 
    	COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_mission,
        SUM(nb_suite) AS Injonction
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Injonction')
    GROUP BY 
    	identifiant_mission,
		COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '')
)
, Prescription AS (
    SELECT 
    	COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_mission,
        SUM(nb_suite) AS Prescription
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Prescription')
    GROUP BY 
    	identifiant_mission,
		COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '')
)
, Coercitif AS (
    SELECT 
    	COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_mission,
        SUM(nb_suite) AS Coercitif
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN (
    		'Injonction',
    		'Prescription')
    GROUP BY 
    	identifiant_mission,
		COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '')
)
, Recommandation AS (
    SELECT 
    	COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '') AS ref,
        identifiant_mission,
        SUM(nb_suite) AS Recommandation
    FROM {{ ref('inspection_controle_PA__suites') }}
    WHERE 
    	type_de_decision IN ('Recommandation')
    GROUP BY 
    	identifiant_mission,
		COALESCE(identifiant_mission, '') || COALESCE(statut_juridique_cd, '')
)
, raw AS (
	SELECT
		Reference.ref,
		Reference.identifiant_mission,	
		Injonction.Injonction,
		Prescription.Prescription,
		Coercitif.Coercitif,
		Recommandation.Recommandation
	FROM Reference
	LEFT JOIN Injonction ON Reference.ref = Injonction.ref
	LEFT JOIN Prescription ON Reference.ref = Prescription.ref
	LEFT JOIN Coercitif ON Reference.ref = Coercitif.ref
	LEFT JOIN Recommandation ON Reference.ref = Recommandation.ref
)

SELECT 
	COUNT(DISTINCT identifiant_mission) AS "Nombre total de missions d'I-C",
	SUM(Injonction) AS "Nombre total d'injonctions",
	ROUND((CAST(SUM(Injonction) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT identifiant_mission) AS FLOAT), 0)), 2) AS "Nombre moyen d'injonctions par mission d'I-C",
	SUM(Prescription) AS 'Nombre total de prescriptions',
	ROUND((CAST(SUM(Prescription) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT identifiant_mission) AS FLOAT), 0)), 2) AS "Nombre moyen de prescriptions par mission d'I-C",
	SUM(Coercitif) AS 'Nombre total de suites coercitives',
	ROUND((CAST(SUM(Coercitif) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT identifiant_mission) AS FLOAT), 0)), 2) AS "Nombre moyen de suites coercitives par mission d'I-C",
	SUM(Recommandation) AS 'Nombre total de recommandations',
	ROUND((CAST(SUM(Recommandation) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT identifiant_mission) AS FLOAT), 0)), 2) AS "Nombre moyen de recommandations par mission d'I-C"
FROM raw