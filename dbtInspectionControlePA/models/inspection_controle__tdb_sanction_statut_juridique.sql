-- Modèle DBT pour TDB_SANCTION_STATUT_JURIDIQUE

with 
missions_real as (
    select 
        coalesce(reg_lb, '') || coalesce(statut_juridique_lb, '') as id_ref,
        reg_lb,
        statut_juridique_lb,
        count(distinct "Identifiant de la mission") as nb_missions_real
    from {{ ref('inspection_controle__missions') }}
    group by reg_lb, statut_juridique_lb
),

missions_clo_ss_s as (
    select 
        coalesce(reg_lb, '') || coalesce(statut_juridique_lb, '') as id_ref,
        reg_lb,
        statut_juridique_lb,
        count(distinct identifiant_mission) as nb_missions_cloturees_sans_s
    from {{ ref('inspection_controle__missions_sanction') }}
    where sanction = 'sans sanction'
    group by reg_lb, statut_juridique_lb
),

injonctions as (
    select 
        coalesce(reg_lb, '') || coalesce(statut_juridique_lb, '') as id_ref,
        reg_lb,
        statut_juridique_lb,
        sum(nb_suite) as nb_injonctions
    from {{ ref('inspection_controle__suites') }}
    where type_de_decision = 'Injonction'
    group by reg_lb, statut_juridique_lb
),

prescriptions as (
    select 
        coalesce(reg_lb, '') || coalesce(statut_juridique_lb, '') as id_ref,
        reg_lb,
        statut_juridique_lb,
        sum(nb_suite) as nb_prescriptions
    from {{ ref('inspection_controle__suites') }}
    where type_de_decision = 'Prescription'
    group by reg_lb, statut_juridique_lb
),

reference as (
    select id_ref, reg_lb, statut_juridique_lb from missions_real
    union select id_ref, reg_lb, statut_juridique_lb from missions_clo_ss_s
    union select id_ref, reg_lb, statut_juridique_lb from injonctions
    union select id_ref, reg_lb, statut_juridique_lb from prescriptions
),

cross_all as (
    select 
        ref.reg_lb as "Région",
        ref.statut_juridique_lb as "Statut juridique",
        mr.nb_missions_real as "I-C d'EHPAD réalisées",
        mc.nb_missions_cloturees_sans_s as "Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine",
        i.nb_injonctions as "Total injonctions",
        cast(i.nb_injonctions as float) / nullif(cast(mr.nb_missions_real as float), 0) as "Nombre moyen d'injonctions / I-C réalisé",
        p.nb_prescriptions as "Total prescriptions",
        cast(p.nb_prescriptions as float) / nullif(cast(mr.nb_missions_real as float), 0) as "Nombre moyen de prescriptions / I-C réalisé",
        i.nb_injonctions + p.nb_prescriptions as "Total injonctions et prescriptions",
        cast(i.nb_injonctions + p.nb_prescriptions as float) / nullif(cast(mr.nb_missions_real as float), 0) as "Nombre moyen d'injonctions et de prescriptions / I-C réalisé",
        cast(i.nb_injonctions as float) / nullif(cast(i.nb_injonctions + p.nb_prescriptions as float), 0) * 100 as "Part injonctions (en %)",
        cast(p.nb_prescriptions as float) / nullif(cast(i.nb_injonctions + p.nb_prescriptions as float), 0) * 100 as "Part prescriptions (en %)"
    from reference ref
    left join missions_real mr on ref.id_ref = mr.id_ref
    left join missions_clo_ss_s mc on ref.id_ref = mc.id_ref
    left join injonctions i on ref.id_ref = i.id_ref
    left join prescriptions p on ref.id_ref = p.id_ref
)

select * from cross_all