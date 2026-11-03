-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
WITH device_exposure_hashed AS (
SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS device_exposure_id,
    per.person_id AS person_id,
    src.target_concept_id AS device_concept_id,
    CAST(src.start_datetime AS DATE) AS device_exposure_start_date,
    src.start_datetime AS device_exposure_start_datetime,
    CAST(src.end_datetime AS DATE) AS device_exposure_end_date,
    src.end_datetime AS device_exposure_end_datetime,
    src.type_concept_id AS device_type_concept_id,
    CAST(NULL AS VARCHAR(255)) AS unique_device_id,
    CAST(NULL AS VARCHAR) AS production_id,
    CAST(
        CASE WHEN ROUND(src.quantity) = src.quantity THEN src.quantity ELSE NULL END
        AS INTEGER) AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS device_source_value,
    src.source_concept_id AS device_source_concept_id,
    src.unit_concept_id AS unit_concept_id,
    src.dose_unit_source_code AS unit_source_value,
    src.unit_source_concept_id AS unit_source_concept_id
FROM
    {{ ref('int__lk_drug_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Device'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.load_table_id, src.load_row_id) >> 1 AS BIGINT) AS device_exposure_id,
    per.person_id AS person_id,
    src.target_concept_id AS device_concept_id,
    CAST(src.start_datetime AS DATE) AS device_exposure_start_date,
    src.start_datetime AS device_exposure_start_datetime,
    CAST(src.start_datetime AS DATE) AS device_exposure_end_date,
    src.start_datetime AS device_exposure_end_datetime,
    src.type_concept_id AS device_type_concept_id,
    CAST(NULL AS VARCHAR(255)) AS unique_device_id,
    CAST(NULL AS VARCHAR) AS production_id,
    CAST(
        CASE WHEN ROUND(src.value_as_number) = src.value_as_number THEN src.value_as_number ELSE NULL END
        AS BIGINT) AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS device_source_value,
    src.source_concept_id AS device_source_concept_id,
    src.unit_concept_id AS unit_concept_id,
    src.unit_source_value AS unit_source_value,
    src.unit_source_concept_id AS unit_source_concept_id
FROM
    {{ ref('int__lk_chartevents_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Device'
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY device_exposure_id) AS INTEGER) AS device_exposure_id
)
FROM device_exposure_hashed
