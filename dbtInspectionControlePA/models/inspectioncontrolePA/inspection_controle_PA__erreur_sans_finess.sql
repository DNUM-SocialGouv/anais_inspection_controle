{{ config(
    materialized='view'
) }}

SELECT
*
FROM {{ ref('inspection_controle_PA__missions') }}
WHERE finess_cd = ''