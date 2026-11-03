with lk_visit_no_hadm_all as (
    SELECT
        src.subject_id AS subject_id,
        CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime AS start_datetime,
        -- provider_id is a varchar, order_provider_id doesn't exist
        src.load_row_id AS provider_id,
        --
        src.unit_id AS unit_id,
        src.load_table_id AS load_table_id,
        src.load_row_id AS load_row_id,
        src.trace_id AS trace_id
    FROM
        {{ ref("int__lk_meas_labevents_mapped") }} AS src
    WHERE
        src.hadm_id IS NULL
    UNION ALL
    -- specimen
    SELECT
        src.subject_id AS subject_id,
        CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime AS start_datetime,
        src.provider_id AS provider_id,
        --
        src.unit_id AS unit_id,
        src.load_table_id AS load_table_id,
        src.load_row_id AS load_row_id,
        src.trace_id AS trace_id
    FROM
        {{ ref("int__lk_specimen_mapped") }} AS src
    WHERE
        src.hadm_id IS NULL
    UNION ALL
    -- organism
    SELECT
        src.subject_id AS subject_id,
        CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime AS start_datetime,
        src.provider_id AS provider_id,
        --
        src.unit_id AS unit_id,
        src.load_table_id AS load_table_id,
        src.load_row_id AS load_row_id,
        src.trace_id AS trace_id
    FROM
        {{ ref("int__lk_meas_organism_mapped") }} AS src
    WHERE
        src.hadm_id IS NULL
    UNION ALL
    -- antibiotics
    SELECT
        src.subject_id AS subject_id,
        CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime AS start_datetime,
        src.provider_id AS provider_id,
        --
        src.unit_id AS unit_id,
        src.load_table_id AS load_table_id,
        src.load_row_id AS load_row_id,
        src.trace_id AS trace_id
    FROM
        {{ ref("int__lk_meas_ab_mapped") }} AS src
    WHERE
        src.hadm_id IS NULL
),

lk_visit_no_hadm_dist as (
    SELECT
    src.subject_id AS subject_id,
    src.date_id AS date_id,
    MIN(src.start_datetime) AS start_datetime,
    MAX(src.start_datetime) AS end_datetime,
    'AMBULATORY OBSERVATION' AS admission_type, -- outpatient visit
    MIN(src.provider_id) AS provider_id,
    CAST(NULL AS TEXT) AS admission_location, -- to hospital
    CAST(NULL AS TEXT) AS discharge_location, -- from hospital
    --
    'no_hadm' AS unit_id,
    'lk_visit_no_hadm_all' AS load_table_id,
    0 AS load_row_id,
    json_object(
        'subject_id', src.subject_id,
        'date_id', src.date_id
    )::TEXT AS trace_id
FROM
    lk_visit_no_hadm_all AS src
GROUP BY
    src.subject_id,
    src.date_id
),

-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
lk_visit_hashed as (
SELECT
    CAST(hash(src.subject_id, src.hadm_id, src.start_datetime, src.end_datetime) >> 1 AS BIGINT) AS visit_occurrence_id,
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    CAST(NULL AS DATE) AS date_id,
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime,
    src.admission_type AS admission_type, -- current location
    src.load_row_id AS provider_id,
    src.admission_location AS admission_location, -- to hospital
    src.discharge_location AS discharge_location, -- from hospital
    CONCAT(
        CAST(src.subject_id AS TEXT), '|',
        CAST(src.hadm_id AS TEXT)
    ) AS source_value,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("int__lk_admissions_clean") }} AS src -- adm
UNION ALL
SELECT
    CAST(hash(src.subject_id, src.start_datetime, src.end_datetime) >> 1 AS BIGINT) AS visit_occurrence_id,
    src.subject_id AS subject_id,
    CAST(NULL AS INTEGER) AS hadm_id,
    src.date_id AS date_id,
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime,
    src.admission_type AS admission_type, -- current location
    src.provider_id AS provider_id,
    src.admission_location AS admission_location, -- to hospital
    src.discharge_location AS discharge_location, -- from hospital
    CONCAT(
        CAST(src.subject_id AS TEXT), '|',
        CAST(src.date_id AS TEXT)
    ) AS source_value,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    lk_visit_no_hadm_dist AS src -- adm
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY visit_occurrence_id) AS INTEGER) AS visit_occurrence_id
)
FROM lk_visit_hashed
