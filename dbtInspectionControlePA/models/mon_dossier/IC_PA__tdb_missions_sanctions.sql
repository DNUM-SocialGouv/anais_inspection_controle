CREATE VIEW TDB_MISSIONS_SANCTIONS AS
-- Nombre d'EHPAD différents contrôlés
-- Taux d'EHPAD différents contrôlés (en %) 
WITH ehpad_control AS (
SELECT
reg_lb ,
NB_ETAB_CONTROLE ,
NB_ETAB_CONTROLE_NB_EHPAD 
FROM DWH_MISSIONS_AGG_region
ORDER BY reg_lb ASC
)
-- Nombre d'I-C d'EHPAD réalisées
, missions_real AS (
SELECT 
reg_lb ,
SUM(NB_MISSION) AS NB_MISSIONS
FROM DWH_MISSIONS
--WHERE filtre = ""Hors santé-environnement""
GROUP BY reg_lb
ORDER BY reg_lb ASC
)
-- Nombre d'I-C clôturées
, missions_clot AS (
SELECT 
reg_lb ,
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_MISSIONS_CLOTUREES
FROM DWH_MISSIONS_SANCTION
--WHERE filtre = ""Hors santé-environnement""
GROUP BY reg_lb
ORDER BY reg_lb ASC
)
-- Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine
, missions_clo_ss_s AS (
SELECT 
reg_lb ,
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_MISSIONS_CLOTUREES_SANS_S
FROM DWH_MISSIONS_SANCTION
--WHERE filtre = ""Hors santé-environnement"" 
WHERE SANCTION = ""sans sanction""
GROUP BY reg_lb
ORDER BY reg_lb ASC
)
-- Nombre de signalements au Parquet effectués (art. 40 CPP)
, saisines_parq AS (
SELECT 
reg_lb ,
COUNT(DISTINCT ""Identifiant de la mission"") AS NB_SAISINES_PARQUET
FROM DWH_SUITES
WHERE Complément = ""Saisine parquet""
GROUP BY reg_lb
ORDER BY reg_lb ASC
)
-- nombre d'injonctions
, injonctions AS (
SELECT 
reg_lb ,
SUM(NB_SUITE) AS NB_INJONC
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Injonction""
GROUP BY
reg_lb
)
-- nombre de prescriptions
, prescriptions AS (
SELECT 
reg_lb ,
SUM(NB_SUITE) AS NB_PRESCR
FROM DWH_SUITES 
--WHERE filtre = ""Hors santé-environnement"" 
WHERE ""Type de décision"" = ""Prescription""
GROUP BY
reg_lb
)
-- nombre d'injonctions + prescriptions
, injonc_prescr AS (
SELECT 
reg_lb ,
SUM(NB_SUITE) AS NB_INJONC_PRESCR
FROM DWH_SUITES
--WHERE filtre = ""Hors santé-environnement"" 
WHERE (""Type de décision"" = ""Injonction"" OR ""Type de décision"" = ""Prescription"")
GROUP BY
reg_lb
)
--
-- table qui croise tous les indicateurs
, cross_all AS (
SELECT 
ehpad_control.reg_lb AS ""Région"",
NB_ETAB_CONTROLE AS ""Nombre d'EHPAD différents contrôlés"",
NB_ETAB_CONTROLE_NB_EHPAD AS ""Taux d'EHPAD différents contrôlés (en %)"",
NB_MISSIONS AS ""Nombre d'I-C d'EHPAD réalisées"",
NB_MISSIONS_CLOTUREES AS ""Nombre d'I-C clôturées"",
NB_MISSIONS_CLOTUREES_SANS_S AS ""Nombre d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine"",
-- Taux d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine (en %)
(CAST(NB_MISSIONS_CLOTUREES_SANS_S AS FLOAT) / CAST(NB_MISSIONS_CLOTUREES AS FLOAT))*100 AS ""Taux d'I-C clôturées sans suites coercitives (injonction, prescription) ni saisine (en %)"",
NB_SAISINES_PARQUET AS ""Nombre de signalements au Parquet effectués (art. 40 CPP)"" ,
NB_INJONC AS ""Nbr total injonctions"",
(CAST(NB_INJONC AS FLOAT) / CAST(NB_MISSIONS AS FLOAT)) AS ""Nbr injonctions moyen / I-C réalisé"" ,
NB_PRESCR AS ""Nbr total prescriptions"",
(CAST(NB_PRESCR AS FLOAT) / CAST(NB_MISSIONS AS FLOAT)) AS ""Nbr prescriptions moyen / I-C réalisé"" ,
NB_INJONC_PRESCR AS ""Nbr total injonctions + prescriptions"" ,
(CAST(NB_INJONC_PRESCR AS FLOAT) / CAST(NB_MISSIONS AS FLOAT)) AS ""Nbr injonctions et prescriptions moyen par I-C réalisé""
FROM ehpad_control
LEFT JOIN missions_real ON ehpad_control.reg_lb = missions_real.reg_lb
LEFT JOIN missions_clot ON ehpad_control.reg_lb = missions_clot.reg_lb
LEFT JOIN missions_clo_ss_s ON ehpad_control.reg_lb = missions_clo_ss_s.reg_lb
LEFT JOIN saisines_parq ON ehpad_control.reg_lb = saisines_parq.reg_lb
LEFT JOIN injonctions ON ehpad_control.reg_lb = injonctions.reg_lb
LEFT JOIN prescriptions ON ehpad_control.reg_lb = prescriptions.reg_lb
LEFT JOIN injonc_prescr ON ehpad_control.reg_lb = injonc_prescr.reg_lb
)
SELECT 
*
FROM cross_all