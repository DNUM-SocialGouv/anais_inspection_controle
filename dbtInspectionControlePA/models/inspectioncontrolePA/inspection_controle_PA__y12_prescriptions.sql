{{ config(
    materialized='view'
) }}

WITH detail AS ( 
    -- injonctions par thème, sous-thème et statut juridique
    SELECT 
        theme_decision ,
        sous_theme_decision ,
        SUM(nb_suite) AS 'Prescriptions'
    FROM {{ ref('inspection_controle__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Prescription'
    GROUP BY
        theme_decision ,
        sous_theme_decision
)
, total AS (
    SELECT
        SUM(nb_suite) AS 'Total Prescriptions'
        FROM {{ ref('inspection_controle__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Prescription'
)
SELECT 
    theme_decision,
    sous_theme_decision,
    Prescriptions AS 'Nombre de prescriptions afférentes',
    'Total Prescriptions',
    ROUND((CAST(Prescriptions AS FLOAT) / NULLIF(CAST('Total Prescriptions' AS FLOAT), 0)) * 100, 2) AS '% global'
FROM detail
LEFT JOIN total ON TRUE