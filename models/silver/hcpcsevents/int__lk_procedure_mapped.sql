WITH lk_hcpcsevents_clean AS (
    SELECT
        src.subject_id,
        src.hadm_id,
        adm.dischtime AS start_datetime,
        src.seq_num,
        src.hcpcs_cd,
        src.short_description,
        adm.admit_provider_id AS provider_id,
        src.load_table_id,
        src.load_row_id,
        src.trace_id
    FROM {{ ref("stg__hcpcsevents") }} src
    INNER JOIN {{ ref("stg__admissions") }} adm
        ON src.hadm_id = adm.hadm_id
),

lk_procedures_icd_clean AS (
    SELECT
        src.subject_id,
        src.hadm_id,
        adm.dischtime AS start_datetime,
        REPLACE(src.icd_code, '.', '') AS source_code,
        CASE
            WHEN src.icd_version = 9  THEN 'ICD9Proc'
            WHEN src.icd_version = 10 THEN 'ICD10PCS'
        END AS source_vocabulary_id,
        adm.admit_provider_id AS provider_id,
        src.load_table_id,
        src.load_row_id,
        src.trace_id
    FROM {{ ref("stg__procedures_icd") }} src
    INNER JOIN {{ ref("stg__admissions") }} adm
        ON src.hadm_id = adm.hadm_id
),

lk_icd_proc_concept AS (
    SELECT
        REPLACE(vc.concept_code, '.', '') AS source_code,
        vc.vocabulary_id AS source_vocabulary_id,
        vc.domain_id AS source_domain_id,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id
    FROM {{ ref("stg__voc_concept") }} vc
    LEFT JOIN {{ ref("stg__voc_concept_relationship") }} vcr
        ON vc.concept_id = vcr.concept_id_1
        AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref("stg__voc_concept") }} vc2
        ON vc2.concept_id = vcr.concept_id_2
        AND vc2.standard_concept = 'S'
        AND vc2.invalid_reason IS NULL
    WHERE vc.vocabulary_id IN ('ICD9Proc', 'ICD10PCS')
),

icd_mapped_deduped AS (
    SELECT
        src.*,
        lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        lc.target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        ROW_NUMBER() OVER (
            PARTITION BY src.trace_id
            ORDER BY lc.target_concept_id, lc.source_concept_id
        ) AS rn
    FROM lk_procedures_icd_clean src
    LEFT JOIN lk_icd_proc_concept lc
        ON src.source_code = lc.source_code
       AND src.source_vocabulary_id = lc.source_vocabulary_id
),

lk_itemid_concept AS (
    SELECT
        d_items.itemid,
        vc.domain_id AS source_domain_id,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id
    FROM {{ ref("stg__d_items") }} d_items
    LEFT JOIN {{ ref("stg__voc_concept") }} vc
        ON vc.concept_code = CAST(d_items.itemid AS TEXT)
        AND vc.vocabulary_id IN (
            'mimiciv_proc_itemid',
            'mimiciv_proc_datetimeevents'
        )
    LEFT JOIN {{ ref("stg__voc_concept_relationship") }} vcr
        ON vc.concept_id = vcr.concept_id_1
        AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref("stg__voc_concept") }} vc2
        ON vc2.concept_id = vcr.concept_id_2
        AND vc2.standard_concept = 'S'
        AND vc2.invalid_reason IS NULL
    WHERE d_items.linksto IN ('procedureevents', 'datetimeevents')
),

item_mapped_deduped AS (
    SELECT
        src.*,
        lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        lc.target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        ROW_NUMBER() OVER (
            PARTITION BY src.trace_id
            ORDER BY lc.target_concept_id, lc.source_concept_id,
                src.itemid, src.start_datetime, src.end_datetime, src.quantity, src.provider_id
        ) AS rn
    FROM {{ ref("int__lk_proc_d_items_clean") }} src
    LEFT JOIN lk_itemid_concept lc
        ON src.itemid = lc.itemid
)

-- ======================
-- FINAL UNION
-- ======================

SELECT
    subject_id,
    hadm_id,
    start_datetime,
    start_datetime AS end_datetime,
    32821 AS type_concept_id,
    1 AS quantity,
    NULL AS itemid,
    source_code,
    NULL AS source_label,
    source_vocabulary_id,
    source_domain_id,
    source_concept_id,
    target_domain_id,
    target_concept_id,
    provider_id,
    'proc.procedures_icd' AS unit_id,
    load_table_id,
    load_row_id,
    trace_id
FROM icd_mapped_deduped
WHERE rn = 1

UNION ALL

SELECT
    subject_id,
    hadm_id,
    start_datetime,
    end_datetime,
    32833 AS type_concept_id,
    quantity,
    itemid,
    CAST(itemid AS TEXT) AS source_code,
    NULL AS source_label,
    NULL AS source_vocabulary_id,
    source_domain_id,
    source_concept_id,
    target_domain_id,
    target_concept_id,
    provider_id,
    CONCAT('proc.', unit_id),
    load_table_id,
    load_row_id,
    trace_id
FROM item_mapped_deduped
WHERE rn = 1
