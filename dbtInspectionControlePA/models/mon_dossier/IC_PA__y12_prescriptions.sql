CREATE VIEW y12_prescriptions AS
WITH detail AS ( 
-- injonctions par thème, sous-thème et statut juridique
SELECT 
""Thème Décision"" ,
""Sous-thème Décision"" ,
SUM(NB_SUITE) AS ""Prescriptions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Prescription""
GROUP BY
""Thème Décision"" ,
""Sous-thème Décision""
)
, total AS (
SELECT
SUM(NB_SUITE) AS ""Total Prescriptions""
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Prescription""
)
SELECT 
""Thème Décision"",
""Sous-thème Décision"",
Prescriptions AS ""Nombre de prescriptions afférentes"",
""Total Prescriptions"" ,
ROUND((CAST(Prescriptions AS FLOAT) / NULLIF(CAST(""Total Prescriptions"" AS FLOAT), 0)) * 100, 2) AS ""% global""
FROM detail
LEFT JOIN total"