-- Modèle DBT pour TDB_MISSIONS_SANCTIONS (tableau de bord des missions avec sanctions et suites)

with ehpad_control as (
    select
        reg_lb,
        nb_etab_controle,
        nb_etab_controle_nb_ehpad
    from {{ ref('inspection_controle__missions_agg_region') }}
),

missions_real as (
    select
        reg_lb,
        count(distinct identifiant_de_la_mission) as nb_missions
    from {{ ref('inspection_controle__missions') }}
    group by reg_lb
),

missions_clot as (
    select
        reg_lb,
        count(distinct identifiant_de_la_mission) as nb_missions_cloturees
    from {{ ref('inspection_controle__missions_sanction') }}
    group by reg_lb
),

missions_clo_ss_s as (
    select
        reg_lb,
        count(distinct identifiant_de_la_mission) as nb_missions_cloturees_sans_s
    from {{ ref('inspection_controle__missions_sanction') }}
    where sanction = 'sans sanction'
    group by reg_lb
),

saisines_parq as (
    select
        reg_lb,
        count(distinct identifiant_de_la_mission) as nb_saisines_parquet
    from {{ ref('inspection_controle__suites') }}
    where complement = 'Saisine parquet'
    group by reg_lb
),

injonctions as (
    select
        reg_lb,
        sum(nb_suite) as nb_injonc
    from {{ ref('inspection_controle__suites') }}
    where type_de_decision = 'Injonction'
    group by reg_lb
),

prescriptions as (
    select
        reg_lb,
        sum(nb_suite) as nb_prescr
    from {{ ref('inspection_controle__suites') }}
    where type_de_decision = 'Prescription'
    group by reg_lb
),

injonc_prescr as (
    select
        reg_lb,
        sum(nb_suite) as nb_injonc_prescr
    from {{ ref('inspection_controle__suites') }}
    where type_de_decision in ('Injonction', 'Prescription')
    group by reg_lb
),

cross_all as (
    select
        e.reg_lb as "Région",
        e.nb_etab_controle as "Nombre d'EHPAD différents contrôlés",
        e.nb_etab_controle_nb_ehpad as "Taux d'EHPAD différents contrôlés (en %)",
        m.nb_missions as "Nombre d'I-C d'EHPAD réalisées",
        mc.nb_missions_cloturees as "Nombre d'I-C clôturées",
        ms.nb_missions_cloturees_sans_s as "Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine",
        (cast(ms.nb_missions_cloturees_sans_s as float) / cast(mc.nb_missions_cloturees as float)) * 100
            as "Taux d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine (en %)",
        sp.nb_saisines_parquet as "Nombre de signalements au Parquet effectués (art. 40 CPP)",
        i.nb_injonc as "Nbr total injonctions",
        (cast(i.nb_injonc as float) / cast(m.nb_missions as float))
            as "Nbr injonctions moyen / I-C réalisé",
        p.nb_prescr as "Nbr total prescriptions",
        (cast(p.nb_prescr as float) / cast(m.nb_missions as float))
            as "Nbr prescriptions moyen / I-C réalisé",
        ip.nb_injonc_prescr as "Nbr total injonctions + prescriptions",
        (cast(ip.nb_injonc_prescr as float) / cast(m.nb_missions as float))
            as "Nbr injonctions et prescriptions moyen par I-C réalisé"
    from ehpad_control e
    left join missions_real m on e.reg_lb = m.reg_lb
    left join missions_clot mc on e.reg_lb = mc.reg_lb
    left join missions_clo_ss_s ms on e.reg_lb = ms.reg_lb
    left join saisines_parq sp on e.reg_lb = sp.reg_lb
    left join injonctions i on e.reg_lb = i.reg_lb
    left join prescriptions p on e.reg_lb = p.reg_lb
    left join injonc_prescr ip on e.reg_lb = ip.reg_lb
)

select * from cross_all