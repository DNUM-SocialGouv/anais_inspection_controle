-- Modèle DBT pour DWH_SUITES (missions avec suites identifiées)

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
        m."date_reelle_visite" as date_visite,
        s."Groupe de cibles" as groupe_siicea,
        case when m."type_planification" = 'Inopiné' then 'Programmé' else m."type_planification" end as "type_planification",

        m."mission_conjointe_1",
        m."mission_conjointe_2",

        case
            when lower(m."mission_conjointe_1") like '%conseil départemental%' or lower(m."mission_conjointe_2") like '%conseil départemental%' then 'ARS / CD'
            when m."mission_conjointe_1" in ('', 'Non') then 'Non conjointe'
            else 'ARS + autre administration'
        end as mission_conjointe,

        nullif(m."modalite_mission", '') as "Modalité de la mission"

    from {{ ref('staging__tdb_ic_siicea_missions_real') }} m
    left join {{ ref('staging__tdb_ic_finess_500') }} f on m.cd_finess = f.finess
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
    left join {{ ref('staging__sa_siicea_cibles') }} s on m.cd_finess = s.finess
),

cross_miss_sui as (
    select
        mrc.*,
        d."Type_de_decision",
        d.Complement,
        d."Theme_Decision",
        d."Sous_theme_Decision",
        d."Statut_de_decision",
        coalesce(d.sanction, 'sans_contrainte') as sanction,
        sum(d.nombre) as nb_suite

    from missions_real_complet mrc
    left join (
        select
            "identifiant_mission",
            "Type_de_decision",
            Complement,
            "Theme_Decision",
            "Sous_theme_Decision",
            "Statut_de_decision",
            case
                when "Type_de_decision" in ('Injonction', 'Prescription', 'Saisine') then 'contrainte'
                else 'sans_contrainte'
            end as sanction,
            nombre
        from {{ ref('staging__sa_siicea_suites') }}
    ) d on mrc."identifiant_mission" = d."identifiant_mission"

    group by
        mrc.reg_cd, mrc.reg_lb, mrc.dep_cd, mrc.dep_lb, mrc.com_cd, mrc.com_lb,
        mrc.finess_cd, mrc.cible, mrc."identifiant_mission", mrc.statut_juridique_cd,
        mrc.statut_juridique_lb, mrc.type_de_mission, mrc.ctrl_pl_pi, mrc."statut_mission",
        mrc.date_visite, mrc.groupe_siicea, mrc."type_planification",
        mrc."mission_conjointe_1", mrc."mission_conjointe_2", mrc.mission_conjointe,
        mrc."Modalité de la mission",
        d."Type_de_decision", d.Complement, d."Theme_Decision", d."Sous_theme_Decision", d."Statut_de_decision", d.sanction
)

select * from cross_miss_sui