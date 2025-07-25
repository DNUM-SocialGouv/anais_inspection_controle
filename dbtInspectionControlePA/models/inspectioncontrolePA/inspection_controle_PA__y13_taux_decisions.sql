{{ config(
    materialized='view'
) }}

WITH total AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT( DISTINCT missions_sanction.identifiant_mission ) AS total
    FROM {{ ref('inspection_controle__missions_sanction') }} missions_sanction
    GROUP BY 
        missions_sanction.reg_cd,
        missions_sanction.reg_lb
)
, avec AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT(DISTINCT missions_sanction.identifiant_mission ) AS avec
    FROM {{ ref('inspection_controle__missions_sanction') }} missions_sanction
    WHERE missions_sanction.SANCTION = 'avec sanction'
    GROUP BY 
        missions_sanction.reg_cd,
        missions_sanction.reg_lb
)
, sans AS (
    SELECT
        COALESCE(missions_sanction.reg_cd, '') AS reg_cd,
        missions_sanction.reg_lb,
        COUNT( DISTINCT missions_sanction.identifiant_mission ) AS sans
    FROM {{ ref('inspection_controle__missions_sanction') }} missions_sanction
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
    ROUND((CAST(avec.avec AS FLOAT) / NULLIF(CAST(total.total AS FLOAT), 0)) * 100, 2) AS "Taux de missions d'I-C clôturées avec suite",
    sans.sans,
    ROUND((CAST(sans.sans AS FLOAT) / NULLIF(CAST(total.total AS FLOAT), 0)) * 100, 2) AS "Taux de missions d'I-C clôturées sans suite"
FROM total 
LEFT JOIN avec ON total.reg_cd = avec.reg_cd
left join sans ON total.reg_cd = sans.reg_cd