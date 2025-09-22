{{ config(
    materialized='view'
) }}

SELECT 
*
FROM {{ ref('inspection_controle_PA__missions') }}
WHERE dep_cd = 'NC'