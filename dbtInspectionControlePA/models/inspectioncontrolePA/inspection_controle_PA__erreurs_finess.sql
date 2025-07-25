{{ config(
    materialized='view'
) }}

SELECT 
*
FROM {{ ref('inspection_controle__missions') }}
WHERE dep_cd = 'NC'