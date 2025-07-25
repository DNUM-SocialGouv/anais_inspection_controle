-- Modèle DBT pour la vue DWH_MISSIONS (projet Inspection Contrôle)

with lien_communes as (
    select
        com as code_commune,
        ncc as nom_commune,
        dep as code_departement,
        reg as code_region
    from {{ ref('staging__ref_communes') }}
    where reg != ''
),

missions_real_complet as (
    select
        coalesce(r.reg, 'NC') as reg_cr,
        coalesce(r.libelle, 'NC') as reg_lb,
        coalesce(d.dep, 'NC') as dep_cd,
        coalesce(d.libelle, 'NC') as dep_lb,
        coalesce(f.com_code, 'NC') as com_cd,
        coalesce(c.nom_commune, 'NC') as com_lb,
        coalesce(f.statut_jur_niv2_lib, 'NC') as statut_juridique_lb,
        m.*
    from {{ ref('staging__helios_siicea_missions') }} m
    left join {{ ref('staging__sa_t_finess') }} f
        on m.code_finess = f.et_finess
    left join lien_communes c
        on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d
        on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r
        on c.code_region = r.reg
)

select * from missions_real_complet