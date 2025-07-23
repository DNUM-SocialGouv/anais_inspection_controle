CREATE VIEW y9_taux_decisions AS 
WITH 
detail AS (SELECT 
	""Type de décision"" ,
	COUNT(DISTINCT ""Identifiant de la mission"" ) AS ""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune""
FROM 
	DWH_SUITES
GROUP BY  
	""Type de décision""
)
, total AS (
SELECT 
	COUNT(DISTINCT ""Identifiant de la mission"" ) AS ""Total de missions d'I-C distinctes""
FROM 
	DWH_SUITES
--WHERE 
	--""Type de décision"" IS NOT NULL
)
SELECT
	""Type de décision"",
	""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"",
	""Total de missions d'I-C distinctes"",
	ROUND((CAST(""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"" AS FLOAT) / NULLIF(CAST(""Total de missions d'I-C distinctes"" AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C (tout type d’I-C confondus) d’EHPAD (tout statut confondu ) réalisés avec au moins une décision édictée ou aucune""
FROM 
	detail
LEFT JOIN total"