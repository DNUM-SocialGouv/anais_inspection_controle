{{ config(
    materialized='view'
) }}

WITH detail AS ( 
    -- injonctions par thème, sous-thème et statut juridique
    SELECT 
        theme_decision,
        sous_theme_decision,
        SUM(nb_suite) AS 'Injonctions'
    FROM {{ ref('inspection_controle__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Injonction'
    GROUP BY
        theme_decision,
        sous_theme_decision
)
, total AS (
    SELECT
        SUM(nb_suite) AS 'Total Injonctions'
    FROM {{ ref('inspection_controle__suites') }}
    --WHERE filtre = 'Hors santé-environnement' 
    WHERE type_de_decision = 'Injonction'
)
SELECT 
    theme_decision,
    sous_theme_decision,
    Injonctions AS "Nombre d'injonctions afférentes",
    'Total Injonctions' ,
    ROUND((CAST(Injonctions AS FLOAT) / NULLIF(CAST('Total Injonctions' AS FLOAT), 0)) * 100, 2) AS '% global'
FROM detail
LEFT JOIN total ON TRUE