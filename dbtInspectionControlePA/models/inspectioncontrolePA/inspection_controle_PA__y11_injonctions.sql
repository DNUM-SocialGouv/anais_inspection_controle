{{ config(
    materialized='view'
) }}

WITH detail AS ( 
    -- injonctions par thème, sous-thème et statut juridique
    SELECT 
        theme_decision,
        sous_theme_decision,
        CAST(SUM(nb_suite) AS INTEGER) AS injonctions
    FROM {{ ref('inspection_controle_PA__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Injonction'
    GROUP BY
        theme_decision,
        sous_theme_decision
)
, total AS (
    SELECT
        CAST(SUM(nb_suite) AS INTEGER) AS total_injonctions
    FROM {{ ref('inspection_controle_PA__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Injonction'
)
SELECT 
    theme_decision,
    sous_theme_decision,
    Injonctions AS "Nombre d'injonctions afférentes",
    total_injonctions AS "Total Injonctions" ,
    CAST(ROUND((CAST(injonctions AS NUMERIC) / NULLIF(CAST(total_injonctions AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "% global"
FROM detail
LEFT JOIN total ON TRUE