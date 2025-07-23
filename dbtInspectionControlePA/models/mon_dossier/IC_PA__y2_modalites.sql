CREATE VIEW y2_modalites AS WITH modalites AS (
    SELECT
        CASE 
            WHEN ""Modalité de la mission"" = 'Inopinée' THEN CAST(NB_MISSION AS FLOAT)
        END AS inopinee,
        CASE 
            WHEN ""Modalité de la mission"" = 'Annoncée' THEN CAST(NB_MISSION AS FLOAT)
        END AS anoncee
    FROM DWH_MISSIONS
    WHERE CTRL_PL_PI = ""Sur site""
)
SELECT 
    ROUND((SUM(inopinee) / NULLIF(SUM(inopinee) + SUM(anoncee), 0)) * 100, 2) 
    AS ""Taux d’inspections sur place réalisées de manière inopinée"",
    ROUND((SUM(anoncee) / NULLIF(SUM(inopinee) + SUM(anoncee), 0)) * 100, 2) 
    AS ""Taux d’inspections sur place réalisées de manière annoncée au gestionnaire""
FROM modalites"