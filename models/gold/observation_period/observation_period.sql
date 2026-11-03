with tmp_observation_period_clean AS (
SELECT
    src.person_id AS person_id,
    MIN(src.visit_start_date) AS start_date,
    MAX(src.visit_end_date) AS end_date
FROM
    {{ ref('visit_occurrence') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.condition_start_date) AS start_date,
    MAX(src.condition_end_date) AS end_date
FROM
    {{ ref('condition_occurrence') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.procedure_date) AS start_date,
    MAX(src.procedure_date) AS end_date
FROM
    {{ ref('procedure_occurrence') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.drug_exposure_start_date) AS start_date,
    MAX(src.drug_exposure_end_date) AS end_date
FROM
    {{ ref('drug_exposure') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.device_exposure_start_date) AS start_date,
    MAX(src.device_exposure_end_date) AS end_date
FROM
    {{ ref('device_exposure') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.measurement_date) AS start_date,
    MAX(src.measurement_date) AS end_date
FROM
    {{ ref('measurement') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.specimen_date) AS start_date,
    MAX(src.specimen_date) AS end_date
FROM
    {{ ref('specimen') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.observation_date) AS start_date,
    MAX(src.observation_date) AS end_date
FROM
    {{ ref('observation') }} AS src
GROUP BY
    src.person_id

UNION ALL

SELECT
    src.person_id AS person_id,
    MIN(src.death_date) AS start_date,
    MAX(src.death_date) AS end_date
FROM
    {{ ref('death') }} AS src
GROUP BY
    src.person_id
),

tmp_observation_period AS (
SELECT
    src.person_id AS person_id,
    MIN(src.start_date) AS start_date,
    MAX(src.end_date) AS end_date
FROM
    tmp_observation_period_clean AS src
GROUP BY
    src.person_id
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(src.person_id)) AS INTEGER) AS observation_period_id,
    src.person_id AS person_id,
    MIN(src.start_date) AS observation_period_start_date,
    MAX(src.end_date) AS observation_period_end_date,
    32828 AS period_type_concept_id  -- 32828    OMOP4976901 EHR episode record
FROM
    tmp_observation_period AS src
GROUP BY
    src.person_id