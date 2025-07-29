{{ config(
    materialized='view'
) }}

-- # SCRIPT des missions
-- table lien entre code commune et codes département et région
-- table qui croise ODS_IC avec les ref geo / cibles et fait les autres transfo
WITH missions_real_complet AS (
    SELECT
        CASE
            WHEN missions_real.cd_finess = '' THEN rr.reg
            WHEN rg.reg_cd IS NULL THEN 'NC'
            ELSE rg.reg_cd
        END
        as reg_cd,
        CASE
            WHEN missions_real.cd_finess = '' THEN rr.libelle
            WHEN rg.reg_lb IS NULL THEN 'NC'
            ELSE rg.reg_lb
        END
        as reg_lb,
        CASE
            WHEN missions_real.cd_finess = '' THEN {{ iif_replacement("LENGTH(missions_real.departement)=1", "'0' || missions_real.departement", "missions_real.departement") }}
            WHEN rg.dep_lb IS NULL THEN 'NC'
            ELSE rg.dep_cd
        END
        as dep_cd,
        CASE
            WHEN missions_real.cd_finess = '' THEN rd.libelle
            WHEN rg.dep_lb IS NULL THEN 'NC'
            ELSE rg.dep_lb
        END
        as dep_lb,
        {{ iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }} as com_cd,
        {{ iif_replacement("rg.COM_CD  IS NULL", "'NC'", "rg.COM_LB") }} as com_lb,
        missions_real.cd_finess AS finess_cd,
        missions_real.cible,
        missions_real.identifiant_mission,
        t_finess.statut_jur_niv2_code AS statut_juridique_cd,
        {{ iif_replacement("t_finess.statut_jur_niv2_lib = ''", "'NC'", "t_finess.statut_jur_niv2_lib") }} AS statut_juridique_lb,
        CASE
            WHEN t_finess.statut_jur_niv2_code = '1100' OR t_finess.statut_jur_niv2_code = '1200' THEN 'Organisme public'
            ELSE {{ iif_replacement("t_finess.statut_jur_niv2_lib = ''", "'NC'", "t_finess.statut_jur_niv2_lib") }}
        END AS statut_juridique_lb_corr,
        missions_real.type_mission AS type_de_mission,
        modalite_d_investigation AS ctrl_pl_pi,
        missions_real.statut_mission,
        missions_real.date_reelle_visite,
        --groupe_diamant.GROUPE AS groupe_2,
        sa_cibles.groupe_cibles AS groupe_siicea,
        {{ iif_replacement("missions_real.type_planification = 'Inopiné'", "'Programmé'", "missions_real.type_planification") }} AS type_planification,
        mission_conjointe_1,
        mission_conjointe_2,
        CASE 
            WHEN (mission_conjointe_1 LIKE '%Conseil départemental%' OR mission_conjointe_1 LIKE '%Département%' OR mission_conjointe_2 LIKE '%Conseil départemental%') THEN 'ARS / CD'
            WHEN mission_conjointe_1 = '' OR mission_conjointe_1 = 'Non' THEN 'Non conjointe'
            ELSE 'ARS + autre administration'
        END AS mission_conjointe,
        {{ iif_replacement("missions_real.modalite_mission=''", "'NC'", "missions_real.modalite_mission") }} AS modalite_de_la_mission
    FROM {{ ref('staging__sa_siicea_missions_real') }} missions_real
    LEFT JOIN {{ ref('staging__tdb_ic_finess_500') }} t_finess ON missions_real.cd_finess = t_finess.finess
    LEFT JOIN {{ ref('staging__ref_geo') }} rg ON t_finess.com_code = rg.COM_CD 
    LEFT JOIN {{ ref('staging__ref_departements') }} rd ON ({{ iif_replacement("LENGTH(missions_real.departement)=1", "'0' || missions_real.departement", "missions_real.departement") }}) = rd.DEP 
    LEFT JOIN {{ ref('staging__ref_regions') }} rr ON rd.reg = rr.reg
    LEFT JOIN {{ ref('staging__sa_siicea_cibles') }} sa_cibles ON missions_real.cd_finess = sa_cibles.finess 
)
, cross_miss_sui AS (
    SELECT 
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        missions_real_complet.identifiant_mission,
        statut_juridique_cd,
        statut_juridique_lb,
        statut_juridique_lb_corr,
        '' AS groupe,
        type_de_mission,
        ctrl_pl_pi,
        '' AS group_hsa_sa,
        '' AS filtre,
        statut_mission,
        date_reelle_visite,
        '' AS groupe_2,
        groupe_siicea,
        type_planification,
        mission_conjointe_1,
        mission_conjointe_2,
        mission_conjointe,
        modalite_de_la_mission,
        type_de_decision,
        complement,
        theme_decision,
        sous_theme_decision,
        COALESCE(sanction, 'sans_contrainte') AS sanction,
        SUM(nombre) AS nb_suite
    --nombre
    FROM missions_real_complet
    LEFT JOIN 
        (SELECT 
            identifiant_mission,
            type_de_decision,
            complement,
            theme_decision,
            sous_theme_decision,
            {{ iif_replacement("type_de_decision IN (
                'Injonction',
                'Prescription',
                'Saisine'
                )", "'contrainte'", "'sans_contrainte'") }} AS sanction,
            nombre
        FROM {{ ref('staging__sa_siicea_decisions') }}
    ) decisions ON missions_real_complet.identifiant_mission=decisions.identifiant_mission 
    GROUP BY 
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        missions_real_complet.identifiant_mission,
        statut_juridique_cd,
        statut_juridique_lb,
        statut_juridique_lb_corr,
        groupe,
        type_de_mission,
        ctrl_pl_pi,
        group_hsa_sa,
        filtre,
        statut_mission,
        date_reelle_visite,
        groupe_2,
        groupe_siicea,
        type_planification,
        mission_conjointe_1,
        mission_conjointe_2,
        mission_conjointe,
        modalite_de_la_mission,
        type_de_decision,
        complement,
        theme_decision,
        sous_theme_decision,
        COALESCE(sanction, 'sans_contrainte')
)
, contrainte AS (
    SELECT 
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        identifiant_mission,
        statut_juridique_cd,
        statut_juridique_lb,
        statut_juridique_lb_corr,
        groupe,
        type_de_mission,
        ctrl_pl_pi,
        group_hsa_sa,
        filtre,
        statut_mission,
        date_reelle_visite,
        groupe_2,
        groupe_siicea,
        type_planification,
        mission_conjointe_1,
        mission_conjointe_2,
        mission_conjointe,
        modalite_de_la_mission,
        'avec sanction' AS avec_sanction
    FROM cross_miss_sui
    WHERE sanction = 'contrainte'
    GROUP BY
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        identifiant_mission,
        statut_juridique_cd,
        statut_juridique_lb,
        statut_juridique_lb_corr,
        groupe,
        type_de_mission,
        ctrl_pl_pi,
        group_hsa_sa,
        filtre,
        statut_mission,
        date_reelle_visite,
        groupe_2,
        groupe_siicea,
        type_planification,
        mission_conjointe_1,
        mission_conjointe_2,
        mission_conjointe,
        modalite_de_la_mission
)


select
    mrc.*,
    coalesce(c.avec_sanction, 'sans sanction') as sanction
from missions_real_complet mrc
left join contrainte c on mrc.identifiant_mission = c.identifiant_mission
where mrc.statut_mission = 'Clôturé'
