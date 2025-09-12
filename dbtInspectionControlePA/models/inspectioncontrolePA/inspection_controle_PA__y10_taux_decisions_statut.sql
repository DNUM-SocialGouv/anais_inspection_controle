{{ config(
    materialized='view'
) }}

WITH detail AS (
	SELECT 
		COALESCE(statut_juridique_lb_corr, '') AS statut_juridique_lb_corr2,
		type_de_decision,
		COUNT(DISTINCT identifiant_de_la_mission ) AS "Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"
	FROM {{ ref('inspection_controle_PA__suites') }}
	GROUP BY  
		COALESCE(statut_juridique_lb_corr, ''),
		type_de_decision
)
, total AS (
	SELECT 
		COALESCE(statut_juridique_lb_corr, '') AS statut_juridique_lb_corr2 ,
		COUNT(DISTINCT identifiant_de_la_mission ) AS "Total de missions d'I-C distinctes"
	FROM {{ ref('inspection_controle_PA__suites') }}
	GROUP BY
		COALESCE(statut_juridique_lb_corr, '')
	--WHERE 
		--type_de_decision IS NOT NULL
)

SELECT
	detail.statut_juridique_lb_corr2,
	type_de_decision,
	"Nombre de missions d'I-C distinctes avec au moins une décision ou aucune",
	"Total de missions d'I-C distinctes",
	CAST(ROUND((CAST("Nombre de missions d'I-C distinctes avec au moins une décision ou aucune" AS NUMERIC) / NULLIF(CAST("Total de missions d'I-C distinctes" AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "Taux d'I-C (tout type d'I-C confondus) d'EHPAD (tout statut confondu ) réalisés avec au moins une décision édictée ou aucune"
FROM detail
LEFT JOIN total ON detail.statut_juridique_lb_corr2 = total.statut_juridique_lb_corr2