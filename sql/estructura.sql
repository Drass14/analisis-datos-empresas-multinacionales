-----//* ESTRECTURA Y PRUEBAS*//-------

-- Crear y seleccionar la base de datos:
CREATE DATABASE caso_practico;
USE caso_practico;

-- Crear tabla de países:
CREATE TABLE countries (
    iso3 VARCHAR(3) PRIMARY KEY,
    country_name VARCHAR(100)
);

//* Consultas de comprobación de datos *//

-- Crear la tabla f_reid:
CREATE TABLE f_mreid (
    origin_iso3 VARCHAR(3) NOT NULL,
    destination_iso3 VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    sector_code INT NOT NULL,

    affiliate_count INT DEFAULT NULL,
    operating_revenue_thousand_usd DECIMAL(15,2) DEFAULT NULL,
    employees INT DEFAULT NULL,
    total_assets_thousand_usd DECIMAL(15,2) DEFAULT NULL,

    PRIMARY KEY (origin_iso3, destination_iso3, year,sector_code),

    CONSTRAINT fk_f_mreid_origin
        FOREIGN KEY (origin_iso3)
        REFERENCES countries(iso3),

    CONSTRAINT fk_f_mreid_destination
        FOREIGN KEY (destination_iso3)
        REFERENCES countries(iso3),

    CONSTRAINT fk_f_mreid_year
        FOREIGN KEY (year)
        REFERENCES dim_dates(year),

    CONSTRAINT fk_f_mreid_sector
        FOREIGN KEY (sector_code)
        REFERENCES dim_sectors(sector_code)

) ENGINE=InnoDB;


-- Insertar los datos a f_reid:
INSERT INTO f_mreid (
    origin_iso3,
    destination_iso3,
    year,
    sector_code,
    affiliate_count,
    operating_revenue_thousand_usd,
    employees,
    total_assets_thousand_usd
)

-- Comprobar el número de registros cargados en la tabla:
SELECT COUNT(*) AS total_records
FROM f_mreid;

-- Eliminar la tabla de hechos para poder recrearla:
DROP TABLE IF EXISTS f_mreid;

-- Consultar los registros de origen que faltan:
SELECT DISTINCT
    m.iso3_o,
    m.country_o
FROM mreid_data m
LEFT JOIN countries c
    ON m.iso3_o = c.iso3
WHERE c.iso3 IS NULL
ORDER BY m.iso3_o;

-- Incorporar los países de origen que faltan y actualizar los ya existentes:
INSERT INTO countries (
    iso3,
    country_name
)
SELECT
    TRIM(iso3_o),
    MAX(TRIM(country_o))
FROM mreid_data
WHERE iso3_o IS NOT NULL
  AND TRIM(iso3_o) <> ''
GROUP BY TRIM(iso3_o)
ON DUPLICATE KEY UPDATE
    country_name = VALUES(country_name);

-- Consultar los países de destino que faltan:
SELECT DISTINCT
    m.iso3_d,
    m.country_d
FROM mreid_data m
LEFT JOIN countries c
    ON m.iso3_d = c.iso3
WHERE c.iso3 IS NULL
ORDER BY m.iso3_d;

-- Incorporar los países de destino que faltan y actualizar los ya existentes:
SELECT
    TRIM(iso3_d),
    MAX(TRIM(country_d))
FROM mreid_data
WHERE iso3_d IS NOT NULL
  AND TRIM(iso3_d) <> ''
GROUP BY TRIM(iso3_d)
ON DUPLICATE KEY UPDATE
    country_name = VALUES(country_name);

-- Verificar que no existen países de origen ni destino sin correspondencia.
SELECT
    'STAGING' AS data_source,
    COUNT(*) AS total_records,
    SUM(extensive) AS affiliate_count,
    SUM(operating_revenue) AS operating_revenue,
    SUM(employees) AS employees,
    SUM(total_assets) AS total_assets
FROM mreid_data

UNION ALL

SELECT
    'FACT',
    COUNT(*),
    SUM(affiliate_count),
    SUM(operating_revenue_thousand_usd),
    SUM(employees),
    SUM(total_assets_thousand_usd)
FROM f_mreid;

-- Comprobar el número total de registros de la tabla de hechos:
SELECT COUNT(*) AS total_records
FROM f_mreid;


-- Comparar los registros y los indicadores entre staging y la tabla de hechos:
INSERT INTO countries (
    iso3,
    country_name
)


SELECT
    'ORIGIN' AS country_type,
    COUNT(DISTINCT m.iso3_o) AS missing_countries
FROM mreid_data m
LEFT JOIN countries c
    ON m.iso3_o = c.iso3
WHERE c.iso3 IS NULL

UNION ALL

SELECT
    'DESTINATION',
    COUNT(DISTINCT m.iso3_d)
FROM mreid_data m
LEFT JOIN countries c
    ON m.iso3_d = c.iso3
WHERE c.iso3 IS NULL;

-- Comprobar la cobertura de países, años y sectores de la tabla de hechos:
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT origin_iso3) AS origin_countries,
    COUNT(DISTINCT destination_iso3) AS destination_countries,
    COUNT(DISTINCT year) AS years,
    COUNT(DISTINCT sector_code) AS sectors
FROM f_mreid;

-- Crear tabla currency_api:
CREATE TABLE IF NOT EXISTS currency_api (
    rate_date DATE NOT NULL,
    usd_per_eur DECIMAL(12,6) NOT NULL,
    source VARCHAR(100) NOT NULL,

    PRIMARY KEY (rate_date)
) ENGINE=InnoDB;

SHOW COLUMNS FROM currency_api;
SELECT COUNT(*) AS total_records
FROM currency_api;
SHOW CREATE TABLE dim_exchange_rates;

-- Actualización de la tabla y comprobaciones:
ALTER TABLE dim_exchange_rates
    DROP PRIMARY KEY,
    DROP COLUMN currency,
    CHANGE COLUMN rate eur_per_usd DECIMAL(12,8) NOT NULL,
    ADD COLUMN rate_date DATE NOT NULL AFTER year,
    ADD COLUMN source VARCHAR(150) NOT NULL,
    ADD PRIMARY KEY (year);

DESCRIBE dim_exchange_rates;

SELECT *
FROM currency_api
ORDER BY rate_date
LIMIT 10;

-- Cargar el último tipo de cambio disponible de cada año
INSERT INTO dim_exchange_rates (
    year,
    rate_date,
    eur_per_usd,
    source
)
SELECT
    YEAR(c.rate_date),
    c.rate_date,
    1 / c.usd_per_eur,
    'European Central Bank'
FROM currency_api c
JOIN (
    SELECT
        YEAR(rate_date) AS year,
        MAX(rate_date) AS max_rate_date
    FROM currency_api
    WHERE usd_per_eur > 0
    GROUP BY YEAR(rate_date)
) latest
    ON YEAR(c.rate_date) = latest.year
    AND c.rate_date = latest.max_rate_date
ON DUPLICATE KEY UPDATE
    rate_date = VALUES(rate_date),
    eur_per_usd = VALUES(eur_per_usd),
    source = VALUES(source);

-- Pruebas, análisis y comprovaciones varias
SELECT
    year,
    rate_date,
    eur_per_usd,
    source
FROM dim_exchange_rates
ORDER BY year;

CREATE OR REPLACE VIEW vw_q05_assets_2020 AS

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

SELECT *
FROM vw_q05_assets_2020;

CREATE OR REPLACE VIEW vw_q06_italy_2015 AS
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

SELECT * FROM vw_q06_italy_2015;


