# Análisis de datos de empresas multinacionales

## Descripción del proyecto

Proyecto de Data Analytics desarrollado durante el curso de Data Analyst de EOI. El objetivo es analizar la actividad económica de empresas multinacionales y sus filiales utilizando la base de datos **MREID de la USITC**, correspondiente al periodo 2010–2021.

Se estudian los ingresos, activos, número de empleados y filiales, comparando diferentes países y sectores económicos.

## Objetivos

- Preparar e integrar los datos mediante procesos ETL.
- Automatizar la extracción, transformación y carga de datos con n8n.
- Diseñar y gestionar una base de datos relacional en MySQL.
- Realizar consultas SQL para responder a preguntas de negocio.
- Crear un informe interactivo en Power BI para visualizar los resultados.

## Tecnologías utilizadas

| Tecnología | Aplicación |
|---|---|
| n8n | Automatización de workflows ETL |
| DBX | Almacenamiento y gestión de datos |
| SQL | Consultas y análisis de información |
| DBeaver | Gestión y ejecución de consultas SQL |
| Power BI | Visualización y elaboración de dashboards |
| ECB API | Obtención de tipos de cambio |

## Desarrollo del proyecto

### 1. ETL – n8n
Creación y ejecución de workflows para extraer, transformar y cargar los datos económicos y los tipos de cambio, preparando la información para su análisis.

### 2. Base de datos – MySQL
Diseño de la estructura relacional y almacenamiento de más de 329.000 registros en la tabla principal `f_mreid`, junto con las tablas dimensionales.

### 3. Consultas SQL
Desarrollo de seis consultas para analizar:

- **Q01:** Países con mayor ingreso por empleado.
- **Q02:** Países con menor ingreso por empleado.
- **Q03:** Evolución de la actividad empresarial doméstica en España.
- **Q04:** Evolución de la actividad de empresas extranjeras en España.
- **Q05:** Activos de empresas extranjeras en España, Portugal y Andorra.
- **Q06:** Ingresos y productividad del sector inmobiliario y de alquileres en Italia.

### 4. Visualización – Power BI
Creación de un informe dividido en tres páginas:

- Visión internacional.
- España: análisis sectorial.
- Casos específicos: España, Portugal, Andorra e Italia.

## Resultados

El proyecto permite comparar la actividad de empresas multinacionales entre países, estudiar la evolución de los sectores económicos en España y analizar casos concretos mediante indicadores de ingresos, activos y empleo.

Se han desarrollado seis consultas SQL y un informe interactivo de tres páginas en Power BI.

## Documentación

El desarrollo completo, las consultas y los resultados se encuentran en los archivos incluidos en este repositorio.

---

**Proyecto académico | Curso Data Analyst – EOI | 2026**
