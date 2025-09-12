-- Modèle DBT pour TDB_INJONCTIONS_PRESCRIPTIONS (injonctions + prescriptions par thème, sous-thème et statut juridique)

select
    reg_lb as "Région",
    statut_juridique_lb as "Statut juridique",
    theme_decision as "Thème Décision",
    sous_theme_decision as "Sous-thème Décision",
    CAST(sum(nb_suite) AS INTEGER) as "Injonctions + prescriptions"
from {{ ref('inspection_controle__suites') }}
where type_de_decision in ('Injonction', 'Prescription')
group by
    reg_lb,
    statut_juridique_lb,
    theme_decision,
    sous_theme_decision