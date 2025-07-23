CREATE VIEW y10_taux_decisions_statut AS 
WITH 
detail AS (SELECT 
	COALESCE(statut_juridique_lb_corr, """") AS statut_juridique_lb_corr ,
	""Type de décision"" ,
	COUNT(DISTINCT ""Identifiant de la mission"" ) AS ""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune""
FROM 
	DWH_SUITES
GROUP BY  
	statut_juridique_lb_corr ,
	""Type de décision""
)
, total AS (
SELECT 
	COALESCE(statut_juridique_lb_corr, """") AS statut_juridique_lb_corr ,
	COUNT(DISTINCT ""Identifiant de la mission"" ) AS ""Total de missions d'I-C distinctes""
FROM 
	DWH_SUITES
GROUP BY
	statut_juridique_lb_corr
--WHERE 
	--""Type de décision"" IS NOT NULL
)
SELECT
	detail.statut_juridique_lb_corr ,
	""Type de décision"",
	""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"",
	""Total de missions d'I-C distinctes"",
	ROUND((CAST(""Nombre de missions d'I-C distinctes avec au moins une décision ou aucune"" AS FLOAT) / NULLIF(CAST(""Total de missions d'I-C distinctes"" AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C (tout type d’I-C confondus) d’EHPAD (tout statut confondu ) réalisés avec au moins une décision édictée ou aucune""
FROM 
	detail
LEFT JOIN total ON detail.statut_juridique_lb_corr = total.statut_juridique_lb_corr"