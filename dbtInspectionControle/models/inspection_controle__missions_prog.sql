-- Modèle DBT pour DWH_MISSIONS_PROG (missions programmées enrichies)

with lien_communes as (
    select
        com as code_commune,
        ncc as nom_commune,
        dep as code_departement,
        reg as code_region
    from {{ ref('staging__ref_communes') }}
    where reg != ''
),

missions_prev_complet as (
    select
        coalesce(r.reg, 'NC') as reg_cd,
        coalesce(r.libelle, 'NC') as reg_lb,
        coalesce(d.dep, 'NC') as dep_cd,
        coalesce(d.libelle, 'NC') as dep_lb,
        coalesce(f.com_code, 'NC') as com_cd,
        coalesce(c.nom_commune, 'NC') as com_lb,
        m.cd_finess as finess_cd,
        m.cible,
        m."identifiant_mission",
        f.statut_jur_niv2_code as statut_juridique_cd,
        nullif(f.statut_jur_niv2_lib, '') as statut_juridique_lb,
        m."type_mission" as type_de_mission,

        case
            when lower(m."type_mission") like '%pièce%' then 'Contrôle sur pièces'
            when lower(m."type_mission") like '%inspection%' or lower(m."type_mission") like '%contrôle%' then 'Contrôle sur place'
            when lower(m."type_mission") = 'evaluation' then 'Evaluation'
            when lower(m."type_mission") = 'visites de conformité' then 'Visites de conformité'
            else 'NC'
        end as ctrl_pl_pi,

        m."statut_mission",
        m."date_provisoire_visite" as date_visite,
        s."Groupe de cibles" as groupe_siicea,
        case when m."type_planification" = 'Inopiné' then 'Programmé' else m."type_planification" end as "Type de planification",

        m."mission_conjointe_1",
        m."mission_conjointe_2",

        case
            when lower(m."mission_conjointe_1") like '%conseil départemental%' or lower(m."mission_conjointe_2") like '%conseil départemental%' then 'ARS / CD'
            when m."mission_conjointe_1" in ('', 'Non') then 'Non conjointe'
            else 'ARS + autre administration'
        end as mission_conjointe,

        nullif(m."modalite_mission", '') as "Modalité de la mission"

    from {{ ref('staging__tdb_ic_siicea_missions_prog') }} m
    left join {{ ref('staging__tdb_ic_finess_500') }} f on m.cd_finess = f.finess
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
    left join {{ ref('staging__sa_siicea_cibles') }} s on m.cd_finess = s.finess
),

dwh as (
    select
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        statut_juridique_cd,
        statut_juridique_lb,
        '' as groupe,
        type_de_mission,
        ctrl_pl_pi,
        '' as filtre,
        "statut_mission",
        date_visite,
        '' as groupe_2,
        groupe_siicea,
        "Type de planification",
        mission_conjointe,
        "Modalité de la mission",
        count(distinct "identifiant_mission") as nb_mission
    from missions_prev_complet
    group by
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        statut_juridique_cd,
        statut_juridique_lb,
        groupe,
        type_de_mission,
        ctrl_pl_pi,
        filtre,
        "statut_mission",
        date_visite,
        groupe_2,
        groupe_siicea,
        "Type de planification",
        mission_conjointe,
        "Modalité de la mission"
)

select * from dwh