CREATE VIEW y8_taux_sanction_statut AS 
WITH sans_sanction_prive_non_lucratif AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction_prive_non_lucratif
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
		AND statut_juridique_lb_corr = ""Organisme Privé à But non Lucratif""
)
, total_prive_non_lucratif AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total_prive_non_lucratif
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		statut_juridique_lb_corr = ""Organisme Privé à But non Lucratif""
)
, sans_sanction_prive_commercial AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction_prive_commercial
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
		AND statut_juridique_lb_corr = ""Organisme Privé à Caractère Commercial""
)
, total_prive_commercial AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total_prive_commercial
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		statut_juridique_lb_corr = ""Organisme Privé à Caractère Commercial""
)
, sans_sanction_public AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS sans_sanction_public
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		SANCTION = ""sans sanction""
		AND statut_juridique_lb_corr = ""Organisme public""
)
, total_public AS (
	SELECT
		COUNT(DISTINCT ""Identifiant de la mission"") AS total_public
	FROM 
		DWH_MISSIONS_SANCTION
	WHERE 
		statut_juridique_lb_corr = ""Organisme public""
)
SELECT 
sans_sanction_prive_non_lucratif,
total_prive_non_lucratif,
ROUND((CAST(sans_sanction_prive_non_lucratif AS FLOAT) / NULLIF(CAST(total_prive_non_lucratif AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C (tout type d’I-C confondus) d’EHPAD privés à but non lucratif clôturés sans suite"",
sans_sanction_prive_commercial,
total_prive_commercial,
ROUND((CAST(sans_sanction_prive_commercial AS FLOAT) / NULLIF(CAST(total_prive_commercial AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C (tout type d’I-C confondus) d’EHPAD privés à caractère commercial clôturés sans suite"",
sans_sanction_public,
total_public,
ROUND((CAST(sans_sanction_public AS FLOAT) / NULLIF(CAST(total_public AS FLOAT), 0)) * 100, 2) AS ""Taux d’I-C (tout type d’I-C confondus) d’EHPAD public clôturés sans suite ""
FROM sans_sanction_prive_non_lucratif
LEFT JOIN total_prive_non_lucratif
LEFT JOIN sans_sanction_prive_commercial
LEFT JOIN total_prive_commercial
LEFT JOIN sans_sanction_public
LEFT JOIN total_public"