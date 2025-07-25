{{ config(
    materialized='view'
) }}

SELECT
*
FROM {{ ref('inspection_controle__missions') }}
WHERE code_finess = ''