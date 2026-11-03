-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
WITH condition_occurrence_hashed AS (
SELECT
    CAST(hash(src.load_table_id, src.load_row_id, src.trace_id, src.unit_id) >> 1 AS BIGINT) AS condition_occurrence_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS condition_concept_id,
    CAST(src.start_datetime AS DATE) AS condition_start_date,
    src.start_datetime AS condition_start_datetime,
    CAST(src.end_datetime AS DATE) AS condition_end_date,
    src.end_datetime AS condition_end_datetime,
    src.type_concept_id AS condition_type_concept_id,
    NULL AS condition_status_concept_id,
    CAST(NULL AS VARCHAR(20)) AS stop_reason,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS condition_source_value,
    COALESCE(src.source_concept_id, 0) AS condition_source_concept_id,
    NULL AS condition_status_source_value
FROM
    {{ ref("int__lk_diagnoses_icd_mapped") }} AS src
INNER JOIN
    {{ ref("person") }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON vis.visit_source_value = 
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT  JOIN 
    {{ ref("provider") }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Condition'

UNION ALL

SELECT
    CAST(hash(src.load_table_id, src.load_row_id, src.trace_id, src.unit_id) >> 1 AS BIGINT) AS condition_occurrence_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS condition_concept_id,
    CAST(src.start_datetime AS DATE) AS condition_start_date,
    src.start_datetime AS condition_start_datetime,
    CAST(src.start_datetime AS DATE) AS condition_end_date,
    src.start_datetime AS condition_end_datetime,
    32817 AS condition_type_concept_id, -- EHR Type Concept
    NULL AS condition_status_concept_id,
    CAST(NULL AS VARCHAR(20)) AS stop_reason,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS condition_source_value,
    COALESCE(src.source_concept_id, 0) AS condition_source_concept_id,
    NULL AS condition_status_source_value
FROM
    {{ ref("int__lk_chartevents_condition_mapped") }} AS src
INNER JOIN
    {{ ref("person") }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON vis.visit_source_value = 
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN 
    {{ ref("provider") }} AS prov             
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Condition'

UNION ALL

SELECT
    CAST(hash(src.load_table_id, src.load_row_id, src.trace_id, src.unit_id, src.measurement_id) >> 1 AS BIGINT) AS condition_occurrence_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS condition_concept_id,
    CAST(src.start_datetime AS DATE) AS condition_start_date,
    src.start_datetime AS condition_start_datetime,
    CAST(src.start_datetime AS DATE) AS condition_end_date,
    src.start_datetime AS condition_end_datetime,
    src.type_concept_id AS condition_type_concept_id,
    NULL AS condition_status_concept_id,
    CAST(NULL AS VARCHAR(20)) AS stop_reason,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS condition_source_value,
    COALESCE(src.source_concept_id, 0) AS condition_source_concept_id,
    NULL AS condition_status_source_value
FROM
    {{ ref("int__lk_chartevents_mapped") }} AS src
INNER JOIN
    {{ ref("person") }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON vis.visit_source_value = 
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN 
    {{ ref("provider") }} AS prov            
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Condition'
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY condition_occurrence_id) AS INTEGER) AS condition_occurrence_id
)
FROM condition_occurrence_hashed
