with tmp_measure_unit as (
SELECT
    vc.concept_code AS concept_code,
    vc.vocabulary_id AS vocabulary_id,
    vc.domain_id AS domain_id,
    vc.concept_id AS concept_id,
    ROW_NUMBER() OVER (
        PARTITION BY vc.concept_code
        ORDER BY UPPER(vc.vocabulary_id), vc.concept_id
    ) AS row_num -- for de-duplication
FROM
    {{ ref("stg__voc_concept") }} AS vc
WHERE
    vc.vocabulary_id IN ('UCUM', 'mimiciv_meas_unit', 'mimiciv_meas_wf_unit')
    AND vc.domain_id = 'Unit'
)

SELECT
    vc.concept_code AS source_code,
    vc.vocabulary_id AS source_vocabulary_id,
    vc.domain_id AS source_domain_id,
    vc.concept_id AS source_concept_id,
    vc2.domain_id AS target_domain_id,
    vc2.concept_id AS target_concept_id
FROM
    tmp_measure_unit AS vc
LEFT JOIN
    {{ ref("stg__voc_concept_relationship") }} AS vcr
    ON vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN
    {{ ref("stg__voc_concept") }} AS vc2
    ON vc2.concept_id = vcr.concept_id_2
    -- AND vc2.standard_concept = 'S' -- units like beats/min are allowed to be non-standard
    AND vc2.invalid_reason IS NULL
WHERE
    vc.row_num = 1