CREATE VIEW y11_injonctions AS
WITH detail AS ( 
-- injonctions par thème, sous-thème et statut juridique
SELECT 
""Thème Décision"" ,
""Sous-thème Décision"" ,
SUM(NB_SUITE) AS ""Injonctions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Injonction""
GROUP BY
""Thème Décision"" ,
""Sous-thème Décision""
)
, total AS (
SELECT
SUM(NB_SUITE) AS ""Total Injonctions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Injonction""
)
SELECT 
""Thème Décision"",
""Sous-thème Décision"",
Injonctions AS ""Nombre d’injonctions afférentes"",
""Total Injonctions"" ,
ROUND((CAST(Injonctions AS FLOAT) / NULLIF(CAST(""Total Injonctions"" AS FLOAT), 0)) * 100, 2) AS ""% global""
FROM detail
LEFT JOIN total"