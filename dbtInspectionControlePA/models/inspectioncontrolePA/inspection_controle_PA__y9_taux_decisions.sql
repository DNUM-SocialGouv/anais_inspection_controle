{{ config(
    materialized='view'
) }}

WITH detail AS (
	SELECT 
		type_de_decision ,
		COUNT(DISTINCT identifiant_mission ) AS "Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"
	FROM {{ ref('inspection_controle_PA__suites') }}
	GROUP BY  
		type_de_decision
)
, total AS (
	SELECT 
		COUNT(DISTINCT identifiant_mission ) AS "Total de missions d'I-C distinctes"
	FROM {{ ref('inspection_controle_PA__suites') }}
	--WHERE 
		--type_de_decision IS NOT NULL
)

SELECT
	type_de_decision,
	"Nombre de missions d'I-C distinctes avec au moins une décision ou aucune",
	"Total de missions d'I-C distinctes",
	ROUND((CAST("Nombre de missions d'I-C distinctes avec au moins une décision ou aucune" AS FLOAT) / NULLIF(CAST("Total de missions d'I-C distinctes" AS FLOAT), 0)) * 100, 2) AS "Taux d'I-C (tout type d'I-C confondus) d'EHPAD (tout statut confondu ) réalisés avec au moins une décision édictée ou aucune"
FROM detail
LEFT JOIN total ON TRUE