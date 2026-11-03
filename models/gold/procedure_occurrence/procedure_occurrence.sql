-- each branch's hash id is only a sort key: rows are renumbered below so ids fit in 32 bits
WITH procedure_occurrence_hashed AS (
SELECT
    CAST(hash(src.load_table_id, src.load_row_id, src.unit_id) >> 1 AS BIGINT) AS procedure_occurrence_id,
    per.person_id AS person_id,
    src.target_concept_id AS procedure_concept_id,
    CAST(src.start_datetime AS DATE) AS procedure_date,
    src.start_datetime AS procedure_datetime,
    CAST(src.end_datetime AS DATE) AS procedure_end_date,
    src.end_datetime AS procedure_end_datetime,
    src.type_concept_id AS procedure_type_concept_id,
    0 AS modifier_concept_id,
    CAST(src.quantity AS INTEGER) AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS procedure_source_value,
    src.source_concept_id AS procedure_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS modifier_source_value
FROM
    {{ ref("int__lk_procedure_mapped") }} AS src
INNER JOIN
    {{ ref("person") }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON  vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT  JOIN 
    {{ ref("provider") }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Procedure'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.target_concept_id, vis.visit_occurrence_id, src.start_datetime) >> 1 AS BIGINT) AS procedure_occurrence_id,
    per.person_id AS person_id,
    src.target_concept_id AS procedure_concept_id,
    CAST(src.start_datetime AS DATE) AS procedure_date,
    src.start_datetime AS procedure_datetime,
    CAST(src.end_datetime AS DATE) AS procedure_end_date,
    src.end_datetime AS procedure_end_datetime,
    src.type_concept_id AS procedure_type_concept_id,
    0 AS modifier_concept_id,
    NULL AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS procedure_source_value,
    src.source_concept_id AS procedure_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS modifier_source_value
FROM
    {{ ref("int__lk_observation_mapped") }} AS src
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
    src.target_domain_id = 'Procedure'

UNION ALL

SELECT
    CAST(hash(per.person_id, src.target_concept_id, vis.visit_occurrence_id, src.start_datetime) >> 1 AS BIGINT) AS procedure_occurrence_id,
    per.person_id AS person_id,
    src.target_concept_id AS procedure_concept_id,
    CAST(src.start_datetime AS DATE) AS procedure_date,
    src.start_datetime AS procedure_datetime,
    CAST(src.end_datetime AS DATE) AS procedure_end_date,
    src.end_datetime AS procedure_end_datetime,
    src.type_concept_id AS procedure_type_concept_id,
    0 AS modifier_concept_id,
    NULL AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS procedure_source_value,
    src.source_concept_id AS procedure_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS modifier_source_value
FROM
    {{ ref("int__lk_specimen_mapped") }} AS src
INNER JOIN
    {{ ref("person") }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|',
                COALESCE(CAST(src.hadm_id AS TEXT), CAST(src.date_id AS TEXT)))
LEFT  JOIN 
    {{ ref("provider") }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Procedure'

UNION ALL

SELECT
    CAST(hash(
        per.person_id,
        vis.visit_occurrence_id,
        src.target_concept_id,
        src.start_datetime
    ) >> 1 AS BIGINT) AS procedure_occurrence_id,
    per.person_id AS person_id,
    src.target_concept_id AS procedure_concept_id,
    CAST(src.start_datetime AS DATE) AS procedure_date,
    src.start_datetime AS procedure_datetime,
    CAST(src.start_datetime AS DATE) AS procedure_end_date,
    src.start_datetime AS procedure_end_datetime,
    src.type_concept_id AS procedure_type_concept_id,
    0 AS modifier_concept_id,
    NULL AS quantity,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    NULL AS visit_detail_id,
    src.source_code AS procedure_source_value,
    src.source_concept_id AS procedure_source_concept_id,
    CAST(NULL AS VARCHAR(50)) AS modifier_source_value
FROM {{ ref("int__lk_chartevents_mapped") }} AS src
INNER JOIN {{ ref("person") }} AS per
    ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN {{ ref("visit_occurrence") }} AS vis
    ON vis.visit_source_value =
       CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN {{ ref("provider") }} AS prov
    ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE src.target_domain_id = 'Procedure'
QUALIFY
    ROW_NUMBER() OVER (
        PARTITION BY
            per.person_id,
            vis.visit_occurrence_id,
            src.target_concept_id,
            src.start_datetime,
            src.type_concept_id
        ORDER BY src.trace_id
    ) = 1
)

SELECT * REPLACE (
    CAST(ROW_NUMBER() OVER (ORDER BY procedure_occurrence_id) AS INTEGER) AS procedure_occurrence_id
)
FROM procedure_occurrence_hashed
