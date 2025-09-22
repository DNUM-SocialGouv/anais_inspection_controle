{{ config(
    materialized='view'
) }}

WITH sans_sanction_sur_place AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS sans_sanction_sur_place
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		SANCTION = 'sans sanction'
		AND CTRL_PL_PI = 'Sur site'
)
, total_sur_place AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS total_sur_place
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		CTRL_PL_PI = 'Sur site'
)
, sans_sanction_sur_pieces AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS sans_sanction_sur_pieces
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		SANCTION = 'sans sanction'
		AND CTRL_PL_PI = 'Sur pièces'
)
, total_sur_pieces AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS total_sur_pieces
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		CTRL_PL_PI = 'Sur pièces'
)

SELECT 
	sans_sanction_sur_place,
	total_sur_place,
	CAST(ROUND((CAST(sans_sanction_sur_place AS NUMERIC) / NULLIF(CAST(total_sur_place AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "Taux d'I-C sur place d'EHPAD clôturés sans suite",
	sans_sanction_sur_pieces,
	total_sur_pieces,
	CAST(ROUND((CAST(sans_sanction_sur_pieces AS NUMERIC) / NULLIF(CAST(total_sur_pieces AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "Taux d'I-C sur pièces d'EHPAD clôturés sans suite"
FROM sans_sanction_sur_place
LEFT JOIN total_sur_place ON TRUE
LEFT JOIN sans_sanction_sur_pieces ON TRUE
LEFT JOIN total_sur_pieces ON TRUE