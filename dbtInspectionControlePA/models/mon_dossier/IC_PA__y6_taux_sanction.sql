CREATE VIEW y6_taux_sanction AS 
WITH sans_sanction AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
)
, total AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total
	FROM 
		DWH_MISSIONS_SANCTION
)
, avec_sanction AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS avec_sanction
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""avec sanction""
)
SELECT
    sans_sanction AS ""Nombre d'I-C clôturées sans sanction"",
    total AS ""Nombre total d'I-C clôturées"",
    ROUND((CAST(sans_sanction AS FLOAT) / NULLIF(CAST(total AS FLOAT), 0)) * 100, 2) AS ""Taux d'I-C clôturées sans sanction"",
	avec_sanction AS ""Nombre d'I-C clôturées avec sanction"",
	ROUND((CAST(avec_sanction AS FLOAT) / NULLIF(CAST(total AS FLOAT), 0)) * 100, 2) AS ""Taux d'I-C clôturées avec sanction""
FROM 
	sans_sanction 
LEFT JOIN 
	total
LEFT JOIN 
	avec_sanction"