-- Modèle DBT pour DWH_MISSIONS_AGG_region (agrégation au niveau régional)

with lien_communes as (
    select
        com as code_commune,
        ncc as nom_commune,
        dep as code_departement,
        reg as code_region
    from {{ ref('staging__ref_communes') }}
    where reg != ''
),

compte_ehpad as (
    select
        coalesce(r.reg, 'NC') || coalesce(d.dep, 'NC') || coalesce(f.com_code, 'NC') as id_ref,
        coalesce(r.reg, 'NC') as reg_cd,
        coalesce(r.libelle, 'NC') as reg_lb,
        coalesce(d.dep, 'NC') as dep_cd,
        coalesce(d.libelle, 'NC') as dep_lb,
        coalesce(f.com_code, 'NC') as com_cd,
        coalesce(c.nom_commune, 'NC') as com_lb,
        f.finess,
        f.rs
    from {{ ref('staging__tdb_ic_finess_500') }} f
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
),

compte_ehpad_controles as (
    select
        coalesce(r.reg, 'NC') || coalesce(d.dep, 'NC') || coalesce(f.com_code, 'NC') as id_ref,
        coalesce(r.reg, 'NC') as reg_cd,
        coalesce(r.libelle, 'NC') as reg_lb,
        coalesce(d.dep, 'NC') as dep_cd,
        coalesce(d.libelle, 'NC') as dep_lb,
        coalesce(f.com_code, 'NC') as com_cd,
        coalesce(c.nom_commune, 'NC') as com_lb,
        m.finess_geographique as finess
    from {{ ref('staging__sa_siicea_missions_real') }} m
    left join {{ ref('staging__tdb_ic_finess_500') }} f on m.finess_geographique = f.finess
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
),

compte_missions as (
    select
        coalesce(r.reg, 'NC') || coalesce(d.dep, 'NC') || coalesce(f.com_code, 'NC') as id_ref,
        coalesce(r.reg, 'NC') as reg_cd,
        coalesce(r.libelle, 'NC') as reg_lb,
        coalesce(d.dep, 'NC') as dep_cd,
        coalesce(d.libelle, 'NC') as dep_lb,
        coalesce(f.com_code, 'NC') as com_cd,
        coalesce(c.nom_commune, 'NC') as com_lb,
        m.identifiant_de_la_mission
    from {{ ref('staging__sa_siicea_missions_real') }} m
    left join {{ ref('staging__tdb_ic_finess_500') }} f on m.finess_geographique = f.finess
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
),

reference as (
    select id_ref, reg_cd, reg_lb, dep_cd, dep_lb, com_cd, com_lb from compte_ehpad
    union
    select id_ref, reg_cd, reg_lb, dep_cd, dep_lb, com_cd, com_lb from compte_ehpad_controles
    union
    select id_ref, reg_cd, reg_lb, dep_cd, dep_lb, com_cd, com_lb from compte_missions
),

communes as (
    select
        r.id_ref,
        r.reg_cd,
        r.reg_lb,
        r.dep_cd,
        r.dep_lb,
        r.com_cd,
        r.com_lb,
        count(distinct e.finess) as nb_ehpad,
        count(distinct m.identifiant_de_la_mission) as nb_mission,
        count(distinct c.finess) as nb_etab_controle,
        (cast(count(distinct c.finess) as NUMERIC) / nullif(cast(count(distinct e.finess) as NUMERIC), 0)) * 100 as nb_etab_controle_nb_ehpad
    from reference r
    left join compte_ehpad e on r.id_ref = e.id_ref
    left join compte_ehpad_controles c on r.id_ref = c.id_ref
    left join compte_missions m on r.id_ref = m.id_ref
    group by r.id_ref, r.reg_cd, r.reg_lb, r.dep_cd, r.dep_lb, r.com_cd, r.com_lb
),

regions as (
    select
        reg_cd,
        reg_lb,
        cast(sum(nb_ehpad) as INTEGER) as nb_ehpad,
        cast(sum(nb_mission) as INTEGER) as nb_mission,
        cast(sum(nb_etab_controle) as INTEGER) as nb_etab_controle,
        cast((cast(sum(nb_etab_controle) as NUMERIC) / nullif(cast(sum(nb_ehpad) as NUMERIC), 0)) * 100 AS FLOAT) as nb_etab_controle_nb_ehpad
    from communes
    group by reg_cd, reg_lb
)

select * from regions