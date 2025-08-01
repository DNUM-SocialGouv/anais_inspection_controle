{{ config(
    materialized='view'
) }}


WITH modalites AS (
    SELECT
        CASE 
            WHEN modalite_de_la_mission = 'Inopinée' THEN CAST(nb_mission AS FLOAT)
        END AS inopinee,
        CASE 
            WHEN modalite_de_la_mission = 'Annoncée' THEN CAST(nb_mission AS FLOAT)
        END AS anoncee
    FROM {{ ref('inspection_controle_PA__missions') }}
    WHERE CTRL_PL_PI = 'Sur site'
)

SELECT 
    ROUND((CAST(SUM(inopinee) AS numeric) / NULLIF(CAST(SUM(inopinee) AS numeric) + CAST(SUM(anoncee) AS numeric), 0)) * 100, 2) 
    AS "Taux d'inspections sur place réalisées de manière inopinée",
    ROUND((CAST(SUM(anoncee) AS numeric) / NULLIF(CAST(SUM(inopinee) AS numeric) + CAST(SUM(anoncee) AS numeric), 0)) * 100, 2) 
    AS "Taux d'inspections sur place réalisées de manière annoncée au gestionnaire"
FROM modalites