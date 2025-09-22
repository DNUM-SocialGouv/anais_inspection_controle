{{ config(
    materialized='view'
) }}


WITH modalites AS (
    SELECT
        CASE 
            WHEN modalite_de_la_mission = 'Inopinée' THEN CAST(nb_mission AS NUMERIC)
        END AS inopinee,
        CASE 
            WHEN modalite_de_la_mission = 'Annoncée' THEN CAST(nb_mission AS NUMERIC)
        END AS anoncee
    FROM {{ ref('inspection_controle_PA__missions') }}
    WHERE CTRL_PL_PI = 'Sur site'
)

SELECT 
    CAST(ROUND((CAST(SUM(inopinee) AS NUMERIC) / NULLIF(CAST(SUM(inopinee) AS NUMERIC) + CAST(SUM(anoncee) AS NUMERIC), 0)) * 100, 2) AS FLOAT)
    AS "Taux d'inspections sur place réalisées de manière inopinée",
    CAST(ROUND((CAST(SUM(anoncee) AS NUMERIC) / NULLIF(CAST(SUM(inopinee) AS NUMERIC) + CAST(SUM(anoncee) AS NUMERIC), 0)) * 100, 2) AS FLOAT)
    AS "Taux d'inspections sur place réalisées de manière annoncée au gestionnaire"
FROM modalites