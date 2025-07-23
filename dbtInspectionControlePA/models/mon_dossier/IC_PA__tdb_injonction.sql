CREATE VIEW TDB_INJONCTION AS 
-- injonctions par thème, sous-thème et statut juridique
SELECT 
reg_lb AS ""Région"",
statut_juridique_lb AS ""Statut juridique"",
""Thème Décision"" ,
""Sous-thème Décision"" ,
SUM(NB_SUITE) AS ""Injonctions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Injonction""
GROUP BY
reg_lb ,
statut_juridique_lb,
""Thème Décision"" ,
""Sous-thème Décision"""