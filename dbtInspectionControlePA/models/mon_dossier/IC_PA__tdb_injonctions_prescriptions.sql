CREATE VIEW TDB_INJONCTIONS_PRESCRIPTIONS AS 
-- injonctions + prescriptions par thème, sous thème et statut juridique
SELECT
reg_lb AS ""Région"",
statut_juridique_lb AS ""Statut juridique"",
""Thème Décision"" ,
""Sous-thème Décision"" ,
SUM(NB_SUITE) AS ""Injonctions + prescriptions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE (""Type de décision"" = ""Injonction"" OR ""Type de décision"" = ""Prescription"")
GROUP BY
reg_lb ,
statut_juridique_lb,
""Thème Décision"" ,
""Sous-thème Décision"""