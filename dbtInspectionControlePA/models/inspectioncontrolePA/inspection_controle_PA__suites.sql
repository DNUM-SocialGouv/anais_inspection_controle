{{ config(
    materialized='view'
) }}

-- # SCRIPT des missions
-- table lien entre code commune et codes département et région
-- table qui croise ODS_IC avec les ref geo / cibles et fait les autres transfo
WITH missions_real_complet AS (
    SELECT
        CASE
            WHEN missions_real.finess_geographique = '' THEN rr.reg
            WHEN rg.reg_cd IS NULL THEN 'NC'
            ELSE rg.reg_cd
        END
        as reg_cd,
        CASE
            WHEN missions_real.finess_geographique = '' THEN rr.libelle
            WHEN rg.reg_lb IS NULL THEN 'NC'
            ELSE rg.reg_lb
        END
        as reg_lb,
        CASE
            WHEN missions_real.finess_geographique = '' THEN {{ dbtStaging.iif_replacement("LENGTH(missions_real.departement)=1", "'0' || missions_real.departement", "missions_real.departement") }}
            WHEN rg.dep_lb IS NULL THEN 'NC'
            ELSE rg.dep_cd
        END
        as dep_cd,
        CASE
            WHEN missions_real.finess_geographique = '' THEN rd.libelle
            WHEN rg.dep_lb IS NULL THEN 'NC'
            ELSE rg.dep_lb
        END
        as dep_lb,
        {{ dbtStaging.iif_replacement("t_finess.com_code IS NULL", "'NC'", "t_finess.com_code") }} as com_cd,
        {{ dbtStaging.iif_replacement("rg.com_cd  IS NULL", "'NC'", "rg.com_lb") }} as com_lb,
        missions_real.finess_geographique AS finess_cd,
        missions_real.cible,
        missions_real.identifiant_de_la_mission,
        t_finess.statut_jur_niv2_code AS statut_juridique_cd,
        {{ dbtStaging.iif_replacement("t_finess.statut_jur_niv2_lib = ''", "'NC'", "t_finess.statut_jur_niv2_lib") }} AS statut_juridique_lb,
        missions_real.type_de_mission,
        modalite_d_investigation AS ctrl_pl_pi,
        missions_real.statut_de_la_mission,
        missions_real.date_reelle_visite,
        sa_cibles.groupe_cibles AS groupe_siicea,
        {{ dbtStaging.iif_replacement("missions_real.type_de_planification = 'Inopiné'", "'Programmé'", "missions_real.type_de_planification") }} AS type_de_planification,
        mission_conjointe_avec_1,
        mission_conjointe_avec_2,
        CASE 
            WHEN (mission_conjointe_avec_1 LIKE '%Conseil départemental%' OR mission_conjointe_avec_1 LIKE '%Département%' OR mission_conjointe_avec_2 LIKE '%Conseil départemental%') THEN 'ARS / CD'
            WHEN mission_conjointe_avec_1 = '' OR mission_conjointe_avec_1 = 'Non' THEN 'Non conjointe'
            ELSE 'ARS + autre administration'
        END AS mission_conjointe,
        {{ dbtStaging.iif_replacement("missions_real.modalite_de_la_mission=''", "'NC'"," missions_real.modalite_de_la_mission") }} AS modalite_de_la_mission
    FROM {{ ref('staging__sa_siicea_missions_real') }} missions_real
    LEFT JOIN {{ ref('staging__tdb_ic_finess_500') }} t_finess ON missions_real.finess_geographique = t_finess.finess
    LEFT JOIN {{ ref('staging__ref_geo') }} rg ON t_finess.com_code = rg.com_cd 
    LEFT JOIN {{ ref('staging__ref_departements') }} rd ON ({{ dbtStaging.iif_replacement("LENGTH(missions_real.departement)=1", "'0' || missions_real.departement", "missions_real.departement") }}) = rd.dep 
    LEFT JOIN {{ ref('staging__ref_regions') }} rr ON rd.reg = rr.reg
    LEFT JOIN {{ ref('staging__sa_siicea_cibles') }} sa_cibles ON missions_real.finess_geographique = sa_cibles.finess 
),
dwh AS (
    SELECT 
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
        '' AS groupe,
        type_de_mission,
        CTRL_PL_PI,
        '' AS filtre,
        statut_de_la_mission,
        date_reelle_visite,
        '' AS groupe_2,
        groupe_siicea,
        type_de_planification,
        mission_conjointe,
        modalite_de_la_mission,
        COUNT(DISTINCT 'Identifiant de la mission') AS nb_mission
    FROM missions_real_complet
    GROUP BY 
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
        type_de_mission,
        ctrl_pl_pi,
        statut_de_la_mission,
        date_reelle_visite,
        groupe_siicea,
        type_de_planification,
        mission_conjointe,
        modalite_de_la_mission
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
        Cible,
        missions_real_complet.identifiant_de_la_mission,
        statut_juridique_cd,
        {{ dbtStaging.iif_replacement("statut_juridique_lb IS NULL", "'NC'", "statut_juridique_lb") }} AS statut_juridique_lb,
        CASE
            WHEN statut_juridique_cd = '1100' OR statut_juridique_cd = '1200' THEN 'Organisme public'
            ELSE statut_juridique_lb
        END AS statut_juridique_lb_corr, 
        '' AS groupe,
        type_de_mission,
        CTRL_PL_PI,
        '' AS filtre,
        statut_de_la_mission,
        date_reelle_visite,
        '' AS groupe_2,
        groupe_siicea,
        type_de_planification,
        mission_conjointe_avec_1,
        mission_conjointe_avec_2,
        mission_conjointe,
        modalite_de_la_mission,
        type_de_decision,
        complement,
        theme_decision,
        sous_theme_decision,
        COALESCE(sanction, 'sans_contrainte') AS SANCTION,
        SUM(nombre) AS nb_suite
    --Nombre
    FROM missions_real_complet
    LEFT JOIN 
        (SELECT 
            identifiant_de_la_mission,
            type_de_decision,
            complement,
            theme_decision,
            sous_theme_decision,
            statut_de_decision,
            {{ dbtStaging.iif_replacement("type_de_decision IN (
                'Injonction',
                'Prescription',
                'Saisine'
                )", "'contrainte'", "'sans_contrainte'") }} AS sanction,
            nombre
        FROM {{ ref('staging__sa_siicea_decisions') }}
    ) decisions ON missions_real_complet.identifiant_de_la_mission=decisions.identifiant_de_la_mission 
    GROUP BY 
        reg_cd,
        reg_lb,
        dep_cd,
        dep_lb,
        com_cd,
        com_lb,
        finess_cd,
        cible,
        missions_real_complet.identifiant_de_la_mission,
        statut_juridique_cd,
        statut_juridique_lb,
        groupe,
        type_de_mission,
        ctrl_pl_pi,
        filtre,
        statut_de_la_mission,
        date_reelle_visite,
        groupe_2,
        groupe_siicea,
        type_de_planification,
        mission_conjointe_avec_1,
        mission_conjointe_avec_2,
        mission_conjointe,
        modalite_de_la_mission,
        type_de_decision,
        complement,
        theme_decision,
        sous_theme_decision,
        COALESCE(sanction, 'sans_contrainte')
)

SELECT 
*
FROM cross_miss_sui