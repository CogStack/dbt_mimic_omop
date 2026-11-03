-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
WITH lk_visit_detail_clean_hashed AS (
SELECT
    CAST(hash('transfers', src.subject_id, src.hadm_id, src.load_row_id) >> 1 AS BIGINT) AS visit_detail_id,
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    src.date_id AS date_id,
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime, -- if null, populate with next start_datetime
    CONCAT(
        CAST(src.subject_id AS TEXT), '|',
        COALESCE(CAST(src.hadm_id AS TEXT), CAST(src.date_id AS TEXT)), '|',
        CAST(src.transfer_id AS TEXT)
    ) AS source_value,
    src.current_location AS current_location, -- find prev and next for adm and disch location
    src.load_row_id AS provider_id,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("int__lk_transfers_clean")}} AS src
WHERE
    src.hadm_id IS NOT NULL -- some ER transfers are excluded because not all of them fit to additional single day visits

UNION ALL

SELECT
    CAST(hash('admissions', src.subject_id, src.hadm_id, src.load_row_id) >> 1 AS BIGINT) AS visit_detail_id,
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    CAST(src.start_datetime AS DATE) AS date_id,
    src.start_datetime AS start_datetime,
    CAST(NULL AS TIMESTAMP) AS end_datetime, -- if null, populate with next start_datetime
    CONCAT(
        CAST(src.subject_id AS TEXT), '|',
        CAST(src.hadm_id AS TEXT)
    ) AS source_value,
    src.admission_type AS current_location, -- find prev and next for adm and disch location
    src.load_row_id AS provider_id,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM 
    {{ ref("int__lk_admissions_clean")}} AS src
WHERE
    src.is_er_admission

UNION ALL

SELECT
    CAST(hash('services', src.subject_id, src.hadm_id, src.load_row_id) >> 1 AS BIGINT) AS visit_detail_id,
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    CAST(src.start_datetime AS DATE) AS date_id,
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime,
    CONCAT(
        CAST(src.subject_id AS TEXT), '|',
        CAST(src.hadm_id AS TEXT), '|',
        CAST(src.start_datetime AS TEXT)
    ) AS source_value,
    src.curr_service AS current_location,
    src.load_row_id AS provider_id,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM 
    {{ ref("int__lk_services_clean")}} AS src
WHERE
    src.prev_service = src.lag_service -- ensure that the services sequence is still consistent after removing duplicates
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY visit_detail_id) AS INTEGER) AS visit_detail_id
)
FROM lk_visit_detail_clean_hashed
