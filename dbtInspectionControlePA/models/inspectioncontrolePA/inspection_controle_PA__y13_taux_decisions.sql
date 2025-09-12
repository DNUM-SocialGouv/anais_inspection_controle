{{ config(
    materialized='view'
) }}

WITH total AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT( DISTINCT missions_sanction.identifiant_de_la_mission ) AS total
    FROM {{ ref('inspection_controle_PA__missions_sanction') }} missions_sanction
    GROUP BY 
        missions_sanction.reg_cd,
        missions_sanction.reg_lb
)
, avec AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT(DISTINCT missions_sanction.identifiant_de_la_mission ) AS avec
    FROM {{ ref('inspection_controle_PA__missions_sanction') }} missions_sanction
    WHERE missions_sanction.SANCTION = 'avec sanction'
    GROUP BY 
        missions_sanction.reg_cd,
        missions_sanction.reg_lb
)
, sans AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT( DISTINCT missions_sanction.identifiant_de_la_mission ) AS sans
    FROM {{ ref('inspection_controle_PA__missions_sanction') }} missions_sanction
    WHERE missions_sanction.SANCTION = 'sans sanction'
    GROUP BY 
        missions_sanction.reg_cd,
        missions_sanction.reg_lb
)

SELECT
    total.reg_cd,
    total.reg_lb,
    total.total,
    avec.avec,
    CAST(ROUND((CAST(avec.avec AS NUMERIC) / NULLIF(CAST(total.total AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "Taux de missions d'I-C clôturées avec suite",
    sans.sans,
    CAST(ROUND((CAST(sans.sans AS NUMERIC) / NULLIF(CAST(total.total AS NUMERIC), 0)) * 100, 2) AS FLOAT) AS "Taux de missions d'I-C clôturées sans suite"
FROM total 
LEFT JOIN avec ON total.reg_cd = avec.reg_cd
left join sans ON total.reg_cd = sans.reg_cd