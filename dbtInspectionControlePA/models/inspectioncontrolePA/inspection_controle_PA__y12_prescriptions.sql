{{ config(
    materialized='view'
) }}

WITH detail AS ( 
    -- injonctions par thème, sous-thème et statut juridique
    SELECT 
        theme_decision ,
        sous_theme_decision ,
        SUM(nb_suite) AS prescriptions
    FROM {{ ref('inspection_controle_PA__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Prescription'
    GROUP BY
        theme_decision ,
        sous_theme_decision
)
, total AS (
    SELECT
        SUM(nb_suite) AS total_prescriptions
        FROM {{ ref('inspection_controle_PA__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Prescription'
)
SELECT 
    theme_decision,
    sous_theme_decision,
    Prescriptions AS "Nombre de prescriptions afférentes",
    total_prescriptions AS "Total Prescriptions",
    ROUND((CAST(prescriptions AS NUMERIC) / NULLIF(CAST(total_prescriptions AS NUMERIC), 0)) * 100, 2) AS "% global"
FROM detail
LEFT JOIN total ON TRUE