-- all MEASUREMENT rows with 64-bit hash ids; the gold measurement model renumbers them to 32 bits
-- (renumbering 300M wide rows in one window runs out of memory, so this is done through int__measurement_id_map)
SELECT
    src.measurement_id AS measurement_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS measurement_concept_id,
    CAST(src.start_datetime AS DATE) AS measurement_date,
    src.start_datetime AS measurement_datetime,
    CAST(NULL AS VARCHAR(10)) AS measurement_time,
    32856 AS measurement_type_concept_id, -- OMOP4976929 Lab
    src.operator_concept_id AS operator_concept_id,
    CAST(src.value_as_number AS DOUBLE) AS value_as_number,  -- to move CAST to mapped/clean
    CAST(NULL AS INTEGER) AS value_as_concept_id,
    src.unit_concept_id AS unit_concept_id,
    src.range_low AS range_low,
    src.range_high AS range_high,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS measurement_source_value,
    src.source_concept_id AS measurement_source_concept_id,
    src.unit_source_value AS unit_source_value,
    src.unit_source_concept_id AS unit_source_concept_id,
    src.value_source_value AS value_source_value,
    NULL AS measurement_event_id,
    NULL AS meas_event_field_concept_id
FROM
    {{ ref('int__lk_meas_labevents_mapped') }} src
INNER JOIN
    {{ ref('person') }} per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|',
                COALESCE(CAST(src.hadm_id AS TEXT), CAST(src.date_id AS TEXT)))
LEFT JOIN
    {{ ref('provider') }} prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Measurement'

UNION ALL

SELECT
    src.measurement_id AS measurement_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS measurement_concept_id,
    CAST(src.start_datetime AS DATE) AS measurement_date,
    src.start_datetime AS measurement_datetime,
    CAST(NULL AS VARCHAR(10)) AS measurement_time,
    src.type_concept_id AS measurement_type_concept_id,
    CAST(NULL AS INTEGER) AS operator_concept_id,
    src.value_as_number AS value_as_number,
    src.value_as_concept_id AS value_as_concept_id,
    src.unit_concept_id AS unit_concept_id,
    CAST(NULL AS DOUBLE) AS range_low,
    CAST(NULL AS DOUBLE) AS range_high,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS measurement_source_value,
    src.source_concept_id AS measurement_source_concept_id,
    src.unit_source_value AS unit_source_value,
    src.unit_source_concept_id AS unit_source_concept_id,
    src.value_source_value AS value_source_value,
    NULL AS measurement_event_id,
    NULL AS meas_event_field_concept_id
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
    src.target_domain_id = 'Measurement'

UNION ALL

SELECT
    src.measurement_id AS measurement_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS measurement_concept_id,
    CAST(src.start_datetime AS DATE) AS measurement_date,
    src.start_datetime AS measurement_datetime,
    CAST(NULL AS VARCHAR(10)) AS measurement_time,
    src.type_concept_id AS measurement_type_concept_id,
    CAST(NULL AS INTEGER) AS operator_concept_id,
    CAST(NULL AS DOUBLE) AS value_as_number,
    COALESCE(src.value_as_concept_id, 0) AS value_as_concept_id,
    CAST(NULL AS INTEGER) AS unit_concept_id,
    CAST(NULL AS DOUBLE) AS range_low,
    CAST(NULL AS DOUBLE) AS range_high,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS measurement_source_value,
    src.source_concept_id AS measurement_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS unit_source_value,
    CAST(NULL AS INTEGER) AS unit_source_concept_id,
    src.value_source_value AS value_source_value,
    NULL AS measurement_event_id,
    NULL AS meas_event_field_concept_id
FROM
    {{ ref('int__lk_meas_organism_mapped') }} AS src
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
    src.target_domain_id = 'Measurement'

UNION ALL

SELECT
    src.measurement_id AS measurement_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS measurement_concept_id,
    CAST(src.start_datetime AS DATE) AS measurement_date,
    src.start_datetime AS measurement_datetime,
    CAST(NULL AS VARCHAR(10)) AS measurement_time,
    src.type_concept_id AS measurement_type_concept_id,
    src.operator_concept_id AS operator_concept_id, -- dilution comparison
    src.value_as_number AS value_as_number, -- dilution value
    COALESCE(src.value_as_concept_id, 0) AS value_as_concept_id, -- resistance (interpretation)
    CAST(NULL AS INTEGER) AS unit_concept_id,
    CAST(NULL AS DOUBLE) AS range_low,
    CAST(NULL AS DOUBLE) AS range_high,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS measurement_source_value, -- antibiotic name
    src.source_concept_id AS measurement_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS unit_source_value,
    CAST(NULL AS INTEGER) AS unit_source_concept_id,
    src.value_source_value AS value_source_value, -- resistance source value
    NULL AS measurement_event_id,
    NULL AS meas_event_field_concept_id
FROM
    {{ ref('int__lk_meas_ab_mapped') }} AS src
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
    src.target_domain_id = 'Measurement'

UNION ALL

SELECT
    src.measurement_id AS measurement_id,
    per.person_id AS person_id,
    COALESCE(src.target_concept_id, 0) AS measurement_concept_id,
    CAST(src.start_datetime AS DATE) AS measurement_date,
    src.start_datetime AS measurement_datetime,
    CAST(NULL AS VARCHAR(10)) AS measurement_time,
    src.type_concept_id AS measurement_type_concept_id,
    CAST(NULL AS INTEGER) AS operator_concept_id,
    src.value_as_number AS value_as_number,
    CAST(COALESCE(src.value_as_concept_id, 0) AS INTEGER) AS value_as_concept_id,
    src.unit_concept_id AS unit_concept_id,
    CAST(NULL AS DOUBLE) AS range_low,
    CAST(NULL AS DOUBLE) AS range_high,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS measurement_source_value,
    src.source_concept_id AS measurement_source_concept_id,
    src.unit_source_value AS unit_source_value,
    src.unit_source_concept_id AS unit_source_concept_id,
    src.value_source_value AS value_source_value,
    NULL AS measurement_event_id,
    NULL AS meas_event_field_concept_id
FROM
    {{ ref('int__lk_outputevents_mapped') }} AS src
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