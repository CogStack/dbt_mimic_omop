-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
WITH observation_hashed AS (
SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS observation_id,
    per.person_id AS person_id,
    src.target_concept_id AS observation_concept_id,
    CAST(src.start_datetime AS DATE) AS observation_date,
    src.start_datetime AS observation_datetime,
    src.type_concept_id AS observation_type_concept_id,
    NULL AS value_as_number,
    src.value_as_string AS value_as_string,
    CASE
        WHEN src.value_as_string IS NOT NULL THEN COALESCE(src.value_as_concept_id, 0)
        ELSE NULL
    END AS value_as_concept_id,
    NULL AS qualifier_concept_id,
    NULL AS unit_concept_id,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS observation_source_value,
    src.source_concept_id AS observation_source_concept_id,
    NULL AS unit_source_value,
    CAST(NULL AS VARCHAR(50)) AS qualifier_source_value,
    CAST(NULL AS VARCHAR(50)) AS value_source_value,
    NULL AS observation_event_id,
    NULL AS obs_event_field_concept_id
FROM
    {{ ref('int__lk_observation_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value = CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Observation'
    
UNION ALL

SELECT
    src.measurement_id AS observation_id, -- id is generated already
    per.person_id AS person_id,
    src.target_concept_id AS observation_concept_id,
    CAST(src.start_datetime AS DATE) AS observation_date,
    src.start_datetime AS observation_datetime,
    src.type_concept_id AS observation_type_concept_id,
    src.value_as_number AS value_as_number,
    src.value_source_value AS value_as_string,
    CASE
        WHEN src.value_source_value IS NOT NULL THEN COALESCE(src.value_as_concept_id, 0)
        ELSE NULL
    END AS value_as_concept_id,
    NULL AS qualifier_concept_id,
    src.unit_concept_id AS unit_concept_id,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS observation_source_value,
    src.source_concept_id AS observation_source_concept_id,
    src.unit_source_value AS unit_source_value,
    CAST(NULL AS VARCHAR(50)) AS qualifier_source_value,
    CAST(NULL AS VARCHAR(50)) AS value_source_value,
    NULL AS observation_event_id,
    NULL AS obs_event_field_concept_id
FROM
    {{ ref('int__lk_chartevents_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value = CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Observation'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS observation_id,
    per.person_id AS person_id,
    src.target_concept_id AS observation_concept_id,
    CAST(src.start_datetime AS DATE) AS observation_date,
    src.start_datetime AS observation_datetime,
    src.type_concept_id AS observation_type_concept_id,
    NULL AS value_as_number,
    NULL AS value_as_string,
    NULL AS value_as_concept_id,
    NULL AS qualifier_concept_id,
    NULL AS unit_concept_id,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS observation_source_value,
    src.source_concept_id AS observation_source_concept_id,
    NULL AS unit_source_value,
    CAST(NULL AS VARCHAR(50)) AS qualifier_source_value,
    CAST(NULL AS VARCHAR(50)) AS value_source_value,
    NULL AS observation_event_id,
    NULL AS obs_event_field_concept_id
FROM
    {{ ref('int__lk_procedure_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value = CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Observation'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS observation_id,
    per.person_id AS person_id,
    src.target_concept_id AS observation_concept_id, -- to rename fields in *_mapped
    CAST(src.start_datetime AS DATE) AS observation_date,
    src.start_datetime AS observation_datetime,
    src.type_concept_id AS observation_type_concept_id,
    NULL AS value_as_number,
    NULL AS value_as_string,
    NULL AS value_as_concept_id,
    NULL AS qualifier_concept_id,
    NULL AS unit_concept_id,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS observation_source_value,
    src.source_concept_id AS observation_source_concept_id,
    NULL AS unit_source_value,
    CAST(NULL AS VARCHAR(50)) AS qualifier_source_value,
    CAST(NULL AS VARCHAR(50)) AS value_source_value,
    NULL AS observation_event_id,
    NULL AS obs_event_field_concept_id
FROM
    {{ ref('int__lk_diagnoses_icd_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value = CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Observation'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS observation_id,
    per.person_id AS person_id,
    src.target_concept_id AS observation_concept_id,
    CAST(src.start_datetime AS DATE) AS observation_date,
    src.start_datetime AS observation_datetime,
    src.type_concept_id AS observation_type_concept_id,
    NULL AS value_as_number,
    NULL AS value_as_string,
    NULL AS value_as_concept_id,
    NULL AS qualifier_concept_id,
    NULL AS unit_concept_id,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS observation_source_value,
    src.source_concept_id AS observation_source_concept_id,
    NULL AS unit_source_value,
    CAST(NULL AS VARCHAR(50)) AS qualifier_source_value,
    CAST(NULL AS VARCHAR(50)) AS value_source_value,
    NULL AS observation_event_id,
    NULL AS obs_event_field_concept_id
FROM
    {{ ref('int__lk_specimen_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value = 
            CONCAT(CAST(src.subject_id AS TEXT), '|',
                COALESCE(CAST(src.hadm_id AS TEXT), CAST(src.date_id AS TEXT)))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Observation'
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY observation_id) AS INTEGER) AS observation_id
)
FROM observation_hashed
