WITH lk_diagnoses_icd_clean AS (
    SELECT
        src.subject_id AS subject_id,
        src.hadm_id AS hadm_id,
        CASE
            WHEN src.seq_num > 20 THEN 20
            ELSE src.seq_num
        END AS seq_num,
        COALESCE(adm.edregtime, adm.admittime) AS start_datetime,
        adm.dischtime AS end_datetime,
        src.icd_code AS source_code,
        CASE
            WHEN src.icd_version = 9 THEN 'ICD9CM'
            WHEN src.icd_version = 10 THEN 'ICD10CM'
            ELSE NULL
        END AS source_vocabulary_id,
        adm.admit_provider_id AS provider_id,
        --
        'diagnoses_icd' AS unit_id,
        CONCAT('diagnoses_icd.', src.load_table_id) AS load_table_id,
        src.load_row_id AS load_row_id,
        src.trace_id AS trace_id
    FROM {{ ref("stg__diagnoses_icd") }} AS src
    INNER JOIN {{ ref("stg__admissions") }} AS adm
        ON src.hadm_id = adm.hadm_id
),

mapped AS (
    SELECT
        src.subject_id,
        src.hadm_id,
        src.seq_num,
        src.start_datetime,
        src.end_datetime,
        32821 AS type_concept_id,
        src.provider_id,
        src.source_code,
        src.source_vocabulary_id,
        vc.concept_id AS source_concept_id,
        vc.domain_id AS source_domain_id,
        vc2.concept_id AS target_concept_id,
        vc2.domain_id AS target_domain_id,
        --
        CONCAT('cond.', src.unit_id) AS unit_id,
        src.load_table_id,
        src.load_row_id,
        src.trace_id,
        --
        ROW_NUMBER() OVER (
            PARTITION BY src.trace_id
            ORDER BY vc2.concept_id, vc.concept_id
        ) AS rn
    FROM lk_diagnoses_icd_clean AS src
    LEFT JOIN {{ ref("stg__voc_concept") }} AS vc
        ON REPLACE(vc.concept_code, '.', '') = REPLACE(TRIM(src.source_code), '.', '')
       AND vc.vocabulary_id = src.source_vocabulary_id
    LEFT JOIN {{ ref("stg__voc_concept_relationship") }} AS vcr
        ON vc.concept_id = vcr.concept_id_1
       AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref("stg__voc_concept") }} AS vc2
        ON vc2.concept_id = vcr.concept_id_2
       AND vc2.standard_concept = 'S'
       AND vc2.invalid_reason IS NULL
)

SELECT
    subject_id,
    hadm_id,
    seq_num,
    start_datetime,
    end_datetime,
    type_concept_id,
    provider_id,
    source_code,
    source_vocabulary_id,
    source_concept_id,
    source_domain_id,
    target_concept_id,
    target_domain_id,
    unit_id,
    load_table_id,
    load_row_id,
    trace_id
FROM mapped
WHERE rn = 1