-- Modèle DBT pour TDB_INJONCTION (injonctions par thème, sous-thème et statut juridique)

select
    reg_lb as "Région",
    statut_juridique_lb as "Statut juridique",
    "Theme_Decision" as "Thème Décision",
    "Sous_theme_Decision" as "Sous-thème Décision",
    sum(nb_suite) as "Injonctions"
from {{ ref('inspection_controle__suites') }}
where "Type_de_decision" = 'Injonction'
group by
    reg_lb,
    statut_juridique_lb,
    "Theme_Decision",
    "Sous_theme_Decision"