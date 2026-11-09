/*
PROYECTO FINAL - DATA ANALYTICS
Base de datos: caso_practico
Fuente: USITC MREID Release 1
Periodo: 2010-2021

Archivo: consultas.sql

Descripción:
Contiene las seis consultas SQL obligatorias del proyecto:
Q01. Top 10 países por facturación por empleado.
Q02. 10 países con menor facturación por empleado.
Q03. Actividad doméstica en España por año y sector.
Q04. Filiales extranjeras en España por año y sector.
Q05. Activos de filiales extranjeras en la Península Ibérica.
Q06. Facturación por empleado en Italia.

Las consultas se ejecutan sobre la tabla f_mreid
y utilizan las dimensiones correspondientes.
*/

-- Q01: Top 10 países con mayor facturación por empleado */
SELECT
    c.country_name AS destination_country,
    totals.revenue_thousand_usd,
    totals.total_employees,
    (totals.revenue_thousand_usd * 1000)
        / totals.total_employees AS revenue_per_employee_usd
FROM (
    SELECT
        destination_iso3,
        SUM(operating_revenue_thousand_usd) AS revenue_thousand_usd,
        SUM(employees) AS total_employees
    FROM f_mreid
    WHERE year = 2021
      AND operating_revenue_thousand_usd > 0
    GROUP BY destination_iso3
    HAVING SUM(employees) >= 100
) AS totals
LEFT JOIN countries c
    ON totals.destination_iso3 = c.iso3
ORDER BY revenue_per_employee_usd DESC
LIMIT 10;

/* Q02: 10 países con menor facturación por empleado */
SELECT
    c.country_name AS destination_country,
    totals.revenue_thousand_usd,
    totals.total_employees,
    (totals.revenue_thousand_usd * 1000)
        / totals.total_employees AS revenue_per_employee_usd
FROM (
    SELECT
        destination_iso3,
        SUM(operating_revenue_thousand_usd) AS revenue_thousand_usd,
        SUM(employees) AS total_employees
    FROM f_mreid
    WHERE year = 2021
      AND operating_revenue_thousand_usd > 0
    GROUP BY destination_iso3
    HAVING SUM(employees) >= 100
) AS totals
LEFT JOIN countries c
    ON totals.destination_iso3 = c.iso3
ORDER BY revenue_per_employee_usd ASC
LIMIT 10;

/* Q03. Obtén las filiales y activos por sector entre 2010 y 2021) */
SELECT
    f.year,
    f.sector_code,
    s.sector_description,
    SUM(f.affiliate_count) AS total_affiliates,
    SUM(f.total_assets_thousand_usd) AS total_assets_thousand_usd
FROM f_mreid f
LEFT JOIN dim_sectors s
    ON f.sector_code = s.sector_code
WHERE f.origin_iso3 = 'ESP'
  AND f.destination_iso3 = 'ESP'
  AND f.year BETWEEN 2010 AND 2021
GROUP BY
    f.year,
    f.sector_code,
    s.sector_description
ORDER BY
    f.year ASC,
    f.sector_code ASC;

/* Q04. Obtén el nº de filiales extranjeras e inversión en activos por sector, 2010-2021 */
SELECT
    f.year,
    f.sector_code,
    s.sector_description,
    SUM(f.affiliate_count) AS total_affiliates,
    SUM(f.total_assets_thousand_usd) AS total_assets_thousand_usd
FROM f_mreid f
LEFT JOIN dim_sectors s
    ON f.sector_code = s.sector_code
WHERE f.destination_iso3 = 'ESP'
  AND f.origin_iso3 <> 'ESP'
  AND f.year BETWEEN 2010 AND 2021
GROUP BY
    f.year,
    f.sector_code,
    s.sector_description
ORDER BY
    f.year ASC,
    f.sector_code ASC;

/* Q05: Obtén la inversión extranjera (en EUR) en la Península Ibérica en 2020 */
SELECT
    f.destination_iso3 AS destination_country,
    SUM(f.total_assets_thousand_usd) AS total_assets_thousand_usd,
    er.eur_per_usd,
    SUM(f.total_assets_thousand_usd)
        * er.eur_per_usd / 1000 AS total_assets_million_eur
FROM f_mreid f
JOIN dim_exchange_rates er
    ON f.year = er.year
WHERE f.year = 2020
  AND f.sector_code = 52
  AND f.destination_iso3 IN ('ESP', 'PRT', 'AND')
  AND f.origin_iso3 <> f.destination_iso3
GROUP BY
    f.destination_iso3,
    er.eur_per_usd

UNION ALL

SELECT
    'TOTAL' AS destination_country,
    SUM(f.total_assets_thousand_usd),
    er.eur_per_usd,
    SUM(f.total_assets_thousand_usd)
        * er.eur_per_usd / 1000
FROM f_mreid f
JOIN dim_exchange_rates er
    ON f.year = er.year
WHERE f.year = 2020
  AND f.sector_code = 52
  AND f.destination_iso3 IN ('ESP', 'PRT', 'AND')
  AND f.origin_iso3 <> f.destination_iso3
GROUP BY er.eur_per_usd;

/* Q06:  Obtén facturación en Italia en 2015 para el sector Real Estate (en EUR) */
SELECT
    c.country_name AS destination_country,
    f.year,
    f.sector_code,
    s.sector_description,
    SUM(f.operating_revenue_thousand_usd) AS revenue_thousand_usd,
    SUM(f.operating_revenue_thousand_usd)
        * 1000 * er.eur_per_usd AS revenue_eur,
    SUM(f.employees) AS total_employees,
    CASE
        WHEN SUM(f.employees) > 0 THEN
            SUM(f.operating_revenue_thousand_usd)
                * 1000 * er.eur_per_usd
                / SUM(f.employees)
        ELSE NULL
    END AS revenue_per_employee_eur
FROM f_mreid f
JOIN dim_exchange_rates er
    ON f.year = er.year
LEFT JOIN dim_sectors s
    ON f.sector_code = s.sector_code
LEFT JOIN countries c
    ON f.destination_iso3 = c.iso3
WHERE f.destination_iso3 = 'ITA'
  AND f.year = 2015
  AND f.sector_code = 53
GROUP BY
    c.country_name,
    f.year,
    f.sector_code,
    s.sector_description,
    er.eur_per_usd;