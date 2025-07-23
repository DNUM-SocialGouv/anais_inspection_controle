CREATE VIEW y13_taux_decisions AS
WITH 
total AS (SELECT
COALESCE(DWH_MISSIONS_SANCTION.reg_cd, """") AS reg_cd
, DWH_MISSIONS_SANCTION.reg_lb
, COUNT( DISTINCT DWH_MISSIONS_SANCTION.""Identifiant de la mission"" ) AS total
FROM DWH_MISSIONS_SANCTION
GROUP BY DWH_MISSIONS_SANCTION.reg_cd)
, avec AS (
SELECT
COALESCE(DWH_MISSIONS_SANCTION.reg_cd, """") AS reg_cd
, DWH_MISSIONS_SANCTION.reg_lb
, COUNT( DISTINCT DWH_MISSIONS_SANCTION.""Identifiant de la mission"" ) AS avec
FROM DWH_MISSIONS_SANCTION
WHERE DWH_MISSIONS_SANCTION.SANCTION = ""avec sanction""
GROUP BY DWH_MISSIONS_SANCTION.reg_cd )
, sans AS (
SELECT
COALESCE(DWH_MISSIONS_SANCTION.reg_cd, """") AS reg_cd
, DWH_MISSIONS_SANCTION.reg_lb
, COUNT( DISTINCT DWH_MISSIONS_SANCTION.""Identifiant de la mission"" ) AS sans
FROM DWH_MISSIONS_SANCTION
WHERE DWH_MISSIONS_SANCTION.SANCTION = ""sans sanction""
GROUP BY DWH_MISSIONS_SANCTION.reg_cd)
SELECT
total.reg_cd
, total.reg_lb
, total.total
, avec.avec
, ROUND((CAST(avec.avec AS FLOAT) / NULLIF(CAST(total.total AS FLOAT), 0)) * 100, 2) AS ""Taux de missions d'I-C clôturées avec suite""
, sans.sans
, ROUND((CAST(sans.sans AS FLOAT) / NULLIF(CAST(total.total AS FLOAT), 0)) * 100, 2)AS ""Taux de missions d'I-C clôturées sans suite""
FROM total 
LEFT JOIN avec ON total.reg_cd = avec.reg_cd
left join sans ON total.reg_cd = sans.reg_cd"