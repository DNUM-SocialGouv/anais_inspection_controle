{{ config(
    materialized='view'
) }}


WITH juridique AS (
	SELECT 
		CASE
			WHEN statut_juridique_cd = '1100' OR statut_juridique_cd = '1200' THEN CAST(nb_mission AS FLOAT)
		END AS 'public',
		CASE
			WHEN statut_juridique_cd = '2100' THEN CAST(nb_mission AS FLOAT)
		END AS 'Organisme Privé à But non Lucratif', 
		CASE
			WHEN statut_juridique_cd = '2200' THEN CAST(nb_mission AS FLOAT)
		END AS 'Organisme Privé à Caractère Commercial'
	FROM {{ ref('inspection_controle__missions') }}
)

SELECT
	ROUND((SUM('public') / NULLIF(SUM('public') + SUM('Organisme Privé à But non Lucratif') + SUM('Organisme Privé à Caractère Commercial'), 0)) * 100, 2) 
	AS "Taux de missions d'I-C des organismes publics"
	, ROUND((SUM('Organisme Privé à But non Lucratif') / NULLIF(SUM('public') + SUM('Organisme Privé à But non Lucratif') + SUM('Organisme Privé à Caractère Commercial'), 0)) * 100, 2) 
	AS "Taux de missions d'I-C des organismes privés à but lucratif"
	, ROUND((SUM('Organisme Privé à Caractère Commercial') / NULLIF(SUM('public') + SUM('Organisme Privé à But non Lucratif') + SUM('Organisme Privé à Caractère Commercial'), 0)) * 100, 2) 
	AS "Taux de missions d'I-C des organismes privés à caractère commercial"
FROM juridique