{{ config(
    materialized='view'
) }}

WITH sans_sanction AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS sans_sanction
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		sanction = 'sans sanction'
)
, total AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS total
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
)
, avec_sanction AS (
	SELECT
		COUNT(DISTINCT identifiant_de_la_mission) AS avec_sanction
	FROM {{ ref('inspection_controle_PA__missions_sanction') }}
	WHERE 
		sanction = 'avec sanction'
)

SELECT
    sans_sanction AS "Nombre d'I-C clôturées sans sanction",
    total AS "Nombre total d'I-C clôturées",
    ROUND((CAST(sans_sanction AS NUMERIC) / NULLIF(CAST(total AS NUMERIC), 0)) * 100, 2) AS "Taux d'I-C clôturées sans sanction",
	avec_sanction AS "Nombre d'I-C clôturées avec sanction",
	ROUND((CAST(avec_sanction AS NUMERIC) / NULLIF(CAST(total AS NUMERIC), 0)) * 100, 2) AS "Taux d'I-C clôturées avec sanction"
FROM sans_sanction 
LEFT JOIN total ON TRUE
LEFT JOIN avec_sanction ON TRUE