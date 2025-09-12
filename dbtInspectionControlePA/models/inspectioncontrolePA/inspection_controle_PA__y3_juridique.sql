{{ config(
    materialized='view'
) }}


WITH juridique AS (
	SELECT 
		CASE
			WHEN statut_juridique_cd = '1100' OR statut_juridique_cd = '1200' THEN CAST(nb_mission AS INT)
		END AS public,
		CASE
			WHEN statut_juridique_cd = '2100' THEN CAST(nb_mission AS INT)
		END AS organisme_prive_a_but_non_lucratif, 
		CASE
			WHEN statut_juridique_cd = '2200' THEN CAST(nb_mission AS INT)
		END AS organisme_prive_a_caractere_commercial
	FROM {{ ref('inspection_controle_PA__missions') }}
)

SELECT
	CAST(ROUND((SUM(public) / NULLIF(SUM(public) + SUM(organisme_prive_a_but_non_lucratif) + SUM(organisme_prive_a_caractere_commercial), 0)) * 100, 2) AS FLOAT)
	AS "Taux de missions d'I-C des organismes publics",
	CAST(ROUND((SUM(organisme_prive_a_but_non_lucratif) / NULLIF(SUM(public) + SUM(organisme_prive_a_but_non_lucratif) + SUM(organisme_prive_a_caractere_commercial), 0)) * 100, 2) AS FLOAT)
	AS "Taux de missions d'I-C des organismes privés à but lucratif",
	CAST(ROUND((SUM(organisme_prive_a_caractere_commercial) / NULLIF(SUM(public) + SUM(organisme_prive_a_but_non_lucratif) + SUM(organisme_prive_a_caractere_commercial), 0)) * 100, 2) AS FLOAT) 
	AS "Taux de missions d'I-C des organismes privés à caractère commercial"
FROM juridique