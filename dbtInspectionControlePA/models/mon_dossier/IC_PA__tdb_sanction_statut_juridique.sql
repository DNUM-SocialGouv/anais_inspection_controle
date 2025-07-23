CREATE VIEW TDB_SANCTION_STATUT_JURIDIQUE AS
-- 4 431 I-C d'EHPAD réalisées
WITH missions_real AS (
SELECT 
COALESCE(reg_lb, """") || COALESCE(statut_juridique_lb, """") AS ID_REF ,
reg_lb ,
statut_juridique_lb ,
SUM(NB_MISSION) AS NB_MISSIONS_REAL
FROM DWH_MISSIONS
--WHERE filtre = ""Hors santé-environnement""
GROUP BY 
reg_lb ,
statut_juridique_lb 
ORDER BY 
reg_lb ASC,
statut_juridique_lb ASC
)
, missions_clo_ss_s AS (
-- Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine
SELECT 
COALESCE(reg_lb, """") || COALESCE(statut_juridique_lb, """") AS ID_REF ,
reg_lb ,
statut_juridique_lb ,
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_MISSIONS_CLOTUREES_SANS_S
FROM DWH_MISSIONS_SANCTION
--WHERE filtre = ""Hors santé-environnement"" 
WHERE SANCTION = ""sans sanction""
GROUP BY
reg_lb ,
statut_juridique_lb 
ORDER BY 
reg_lb ASC,
statut_juridique_lb ASC
)
, injonctions AS (
-- nombre d'injonctions
SELECT 
COALESCE(reg_lb, """") || COALESCE(statut_juridique_lb, """") AS ID_REF ,
reg_lb ,
statut_juridique_lb ,
SUM(NB_SUITE) AS NB_INJONCTIONS
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Injonction""
GROUP BY
reg_lb ,
statut_juridique_lb 
ORDER BY 
reg_lb ASC,
statut_juridique_lb ASC
)
, prescriptions AS (
-- nombre de prescriptions
SELECT 
COALESCE(reg_lb, """") || COALESCE(statut_juridique_lb, """") AS ID_REF ,
reg_lb ,
statut_juridique_lb ,
SUM(NB_SUITE) AS NB_PRESCRIPTIONS
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Prescription""
GROUP BY
reg_lb ,
statut_juridique_lb 
ORDER BY 
reg_lb ASC,
statut_juridique_lb ASC
)
, reference AS (
		SELECT 
			ID_REF
			, reg_lb
			, statut_juridique_lb
		FROM missions_real
UNION 	SELECT 
			ID_REF
			, reg_lb
			, statut_juridique_lb 
		FROM missions_clo_ss_s
UNION 	SELECT 
			ID_REF
			, reg_lb
			, statut_juridique_lb 
		FROM injonctions
UNION 	SELECT 
			ID_REF
			, reg_lb
			, statut_juridique_lb 
		FROM prescriptions
)
, cross_all AS (
SELECT 
reference.reg_lb AS ""Région"",
reference.statut_juridique_lb AS ""Statut juridique"",
NB_MISSIONS_REAL AS ""I-C d'EHPAD réalisées"",
NB_MISSIONS_CLOTUREES_SANS_S AS ""Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine"",
NB_INJONCTIONS AS ""Total injonctions"",
CAST(NB_INJONCTIONS AS FLOAT) / CAST(NB_MISSIONS_REAL AS FLOAT) AS ""Nombre moyen d'injonctions / I-C réalisé"",
NB_PRESCRIPTIONS AS ""Total prescriptions"",
IFNULL(NB_PRESCRIPTIONS,0) / IFNULL(NB_MISSIONS_REAL,0) AS ""Nombre moyen de prescriptions / I-C réalisé"",
CAST(NB_INJONCTIONS AS FLOAT) + CAST(NB_PRESCRIPTIONS AS FLOAT) AS ""Total injonctions et prescriptions"",
CAST((NB_INJONCTIONS + NB_PRESCRIPTIONS) AS FLOAT) / CAST(NB_MISSIONS_REAL AS FLOAT) AS ""Nombre moyen d'injonctions et de prescriptions / I-C réalisé"",
(CAST(NB_INJONCTIONS AS FLOAT) / CAST((NB_INJONCTIONS + NB_PRESCRIPTIONS) AS FLOAT))*100 AS ""Part injonctions (en %)"",
(CAST(NB_PRESCRIPTIONS AS FLOAT) / CAST((NB_INJONCTIONS + NB_PRESCRIPTIONS) AS FLOAT))*100 AS ""Part prescriptions (en %)""
FROM reference
LEFT JOIN missions_real ON reference.ID_REF = missions_real.ID_REF
LEFT JOIN missions_clo_ss_s ON reference.ID_REF = missions_clo_ss_s.ID_REF
LEFT JOIN injonctions ON reference.ID_REF = injonctions.ID_REF
LEFT JOIN prescriptions ON reference.ID_REF = prescriptions.ID_REF
)
SELECT 
*
FROM cross_all"