CREATE VIEW y7_taux_sanction_modalite AS 
WITH sans_sanction_sur_place AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction_sur_place
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
		AND CTRL_PL_PI = ""Sur site""
)
, total_sur_place AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total_sur_place
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		CTRL_PL_PI = ""Sur site""
)
, sans_sanction_sur_pieces AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction_sur_pieces
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
		AND CTRL_PL_PI = ""Sur pièces""
)
, total_sur_pieces AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total_sur_pieces
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		CTRL_PL_PI = ""Sur pièces""
)
SELECT 
sans_sanction_sur_place,
total_sur_place,
ROUND((CAST(sans_sanction_sur_place AS FLOAT) / NULLIF(CAST(total_sur_place AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C sur place d’EHPAD clôturés sans suite"" ,
sans_sanction_sur_pieces,
total_sur_pieces,
ROUND((CAST(sans_sanction_sur_pieces AS FLOAT) / NULLIF(CAST(total_sur_pieces AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C sur pièces d’EHPAD clôturés sans suite"" 
FROM sans_sanction_sur_place
LEFT JOIN total_sur_place
LEFT JOIN sans_sanction_sur_pieces
LEFT JOIN total_sur_pieces"