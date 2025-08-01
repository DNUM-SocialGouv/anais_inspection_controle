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
        m.finess_geographique as finess_cd,
        m.cible,
        m.identifiant_de_la_mission,
        f.statut_jur_niv2_code as statut_juridique_cd,
        nullif(f.statut_jur_niv2_lib, '') as statut_juridique_lb,
        m.type_de_mission,

        case
            when lower(m.type_de_mission) like '%pièce%' then 'Contrôle sur pièces'
            when lower(m.type_de_mission) like '%inspection%' or lower(m.type_de_mission) like '%contrôle%' then 'Contrôle sur place'
            when lower(m.type_de_mission) = 'evaluation' then 'Evaluation'
            when lower(m.type_de_mission) = 'visites de conformité' then 'Visites de conformité'
            else 'NC'
        end as ctrl_pl_pi,

        m.statut_de_la_mission,
        m.date_reelle_visite as date_visite,
        s.groupe_cibles as groupe_siicea,
        case when m.type_de_planification = 'Inopiné' then 'Programmé' else m.type_de_planification end as type_de_planification,

        m.mission_conjointe_avec_1,
        m.mission_conjointe_avec_2,

        case
            when lower(m.mission_conjointe_avec_1) like '%conseil départemental%' or lower(m.mission_conjointe_avec_2) like '%conseil départemental%' then 'ARS / CD'
            when m.mission_conjointe_avec_1 in ('', 'Non') then 'Non conjointe'
            else 'ARS + autre administration'
        end as mission_conjointe,

        nullif(m.modalite_de_la_mission, '') as modalite_de_la_mission

    from {{ ref('staging__sa_siicea_missions_real') }} m
    left join {{ ref('staging__tdb_ic_finess_500') }} f on m.finess_geographique = f.finess
    left join lien_communes c on f.com_code = c.code_commune
    left join {{ ref('staging__ref_departements') }} d on c.code_departement = d.dep
    left join {{ ref('staging__ref_regions') }} r on c.code_region = r.reg
    left join {{ ref('staging__sa_siicea_cibles') }} s on m.finess_geographique = s.finess
),

cross_miss_sui as (
    select
        mrc.*,
        d.type_de_decision,
        d.complement,
        d.theme_decision,
        d.sous_theme_decision,
        d.statut_de_decision,
        coalesce(d.sanction, 'sans_contrainte') as sanction,
        sum(d.nombre) as nb_suite

    from missions_real_complet mrc
    left join (
        select
            identifiant_de_la_mission,
            type_de_decision,
            complement,
            theme_decision,
            sous_theme_decision,
            statut_de_decision,
            case
                when type_de_decision in ('Injonction', 'Prescription', 'Saisine') then 'contrainte'
                else 'sans_contrainte'
            end as sanction,
            nombre
        from {{ ref('staging__sa_siicea_decisions') }}
    ) d on mrc.identifiant_de_la_mission = d.identifiant_de_la_mission

    group by
        mrc.reg_cd, mrc.reg_lb, mrc.dep_cd, mrc.dep_lb, mrc.com_cd, mrc.com_lb,
        mrc.finess_cd, mrc.cible, mrc.identifiant_de_la_mission, mrc.statut_juridique_cd,
        mrc.statut_juridique_lb, mrc.type_de_mission, mrc.ctrl_pl_pi, mrc.statut_de_la_mission,
        mrc.date_visite, mrc.groupe_siicea, mrc.type_de_planification,
        mrc.mission_conjointe_avec_1, mrc.mission_conjointe_avec_2, mrc.mission_conjointe,
        mrc.modalite_de_la_mission,
        d.type_de_decision, d.complement, d.theme_decision, d.sous_theme_decision, d.statut_de_decision, d.sanction
)

select * from cross_miss_sui