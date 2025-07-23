CREATE VIEW y4_moyennes_suites AS
WITH 
Reference AS (  
SELECT
	DISTINCT (COALESCE(""Identifiant de la mission"", """") || COALESCE(statut_juridique_cd, """")) AS ref,
	""Identifiant de la mission"",
	statut_juridique_cd,
	statut_juridique_lb_corr
FROM 
	DWH_SUITES
)
, Injonction AS (
    SELECT 
    	COALESCE(""Identifiant de la mission"", """") || COALESCE(statut_juridique_cd, """") AS ref,
        ""Identifiant de la mission"",
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(NB_SUITE) AS Injonction
    FROM 
    	DWH_SUITES
    WHERE 
    	""Type de décision"" IN ('Injonction')
    GROUP BY 
    	""Identifiant de la mission"", 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Prescription AS (
    SELECT 
    	COALESCE(""Identifiant de la mission"", """") || COALESCE(statut_juridique_cd, """") AS ref,
        ""Identifiant de la mission"",
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(NB_SUITE) AS Prescription
    FROM 
    	DWH_SUITES
    WHERE 
    	""Type de décision"" IN ('Prescription')
    GROUP BY 
    	""Identifiant de la mission"", 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Coercitif AS (
    SELECT 
    	COALESCE(""Identifiant de la mission"", """") || COALESCE(statut_juridique_cd, """") AS ref,
        ""Identifiant de la mission"",
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(NB_SUITE) AS Coercitif
    FROM 
    	DWH_SUITES
    WHERE 
    	""Type de décision"" IN (
    		'Injonction',
    		'Prescription')
    GROUP BY 
    	""Identifiant de la mission"", 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, Recommandation AS (
    SELECT 
    	COALESCE(""Identifiant de la mission"", """") || COALESCE(statut_juridique_cd, """") AS ref,
        ""Identifiant de la mission"",
        statut_juridique_cd,
        statut_juridique_lb_corr,
        SUM(NB_SUITE) AS Recommandation
    FROM 
    	DWH_SUITES
    WHERE 
    	""Type de décision"" IN ('Recommandation')
    GROUP BY 
    	""Identifiant de la mission"", 
        statut_juridique_cd,
    	statut_juridique_lb_corr
)
, raw AS (
SELECT
	Reference.""ref"",
	Reference.""Identifiant de la mission"",	
	Reference.statut_juridique_cd,	
	Reference.statut_juridique_lb_corr,
	Injonction.Injonction,
	Prescription.Prescription,
	Coercitif.Coercitif,
	Recommandation.Recommandation
FROM 
	Reference
LEFT JOIN 
	Injonction ON Reference.ref = Injonction.ref
LEFT JOIN 
	Prescription ON Reference.ref = Prescription.ref
LEFT JOIN 
	Coercitif ON Reference.ref = Coercitif.ref
LEFT JOIN 
	Recommandation ON Reference.ref = Recommandation.ref
)
SELECT 
	statut_juridique_lb_corr,
	COUNT(DISTINCT ""Identifiant de la mission"") AS ""Nombre total de missions d'I-C""
	,SUM(Injonction) AS ""Nombre total d'injonctions""
	,ROUND((CAST(SUM(Injonction) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT ""Identifiant de la mission"") AS FLOAT), 0)), 2) AS ""Nombre moyen d'injonctions par mission d'I-C""
	,SUM(Prescription) AS ""Nombre total de prescriptions""
	,ROUND((CAST(SUM(Prescription) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT ""Identifiant de la mission"") AS FLOAT), 0)), 2) AS ""Nombre moyen de prescriptions par mission d'I-C""
	,SUM(Coercitif) AS ""Nombre total de suites coercitives""
	,ROUND((CAST(SUM(Coercitif) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT ""Identifiant de la mission"") AS FLOAT), 0)), 2) AS ""Nombre moyen de suites coercitives par mission d'I-C""
	,SUM(Recommandation) AS ""Nombre total de recommandations""
	,ROUND((CAST(SUM(Recommandation) AS FLOAT) / NULLIF(CAST(COUNT(DISTINCT ""Identifiant de la mission"") AS FLOAT), 0)), 2) AS ""Nombre moyen de recommandations par mission d'I-C""
FROM 	
	raw
GROUP BY 
	statut_juridique_lb_corr"