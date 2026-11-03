WITH lk_outputevents AS (
    SELECT
        src.subject_id,
        src.hadm_id,
        src.stay_id,
        src.caregiver_id AS provider_id,
        src.itemid,
        CAST(src.itemid AS TEXT) AS source_code,
        di.label AS source_label,
        src.charttime AS start_datetime,
        src.value AS valuenum,
        src.valueuom,
        'outputevents' AS unit_id,
        src.load_table_id,
        src.load_row_id,
        src.trace_id,

        -- Semantic grain (DO NOT use as PK)
        CAST(hash(
            src.subject_id,
            src.hadm_id,
            src.stay_id,
            src.charttime,
            src.itemid,
            src.load_row_id
        ) >> 1 AS BIGINT) AS measurement_group_id

    FROM {{ ref("stg__outputevents") }} AS src
    INNER JOIN {{ ref("stg__d_items") }} AS di
        ON src.itemid = di.itemid
),

expanded AS (
    SELECT
        src.*,
        vc.vocabulary_id,
        vc.domain_id AS source_domain_id,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id,
        uc.target_concept_id AS unit_target_concept_id,
        uc.source_concept_id AS unit_source_concept_id,

        ROW_NUMBER() OVER (
            PARTITION BY src.measurement_group_id
            ORDER BY
                vc2.concept_id,
                vc.concept_id
        ) AS row_discriminator

    FROM lk_outputevents AS src
    LEFT JOIN {{ ref("stg__voc_concept") }} AS vc
        ON src.source_code = vc.concept_code
       AND vc.vocabulary_id = 'mimiciv_outputevents'

    LEFT JOIN {{ ref("stg__voc_concept_relationship") }} AS vcr
        ON vc.concept_id = vcr.concept_id_1

    LEFT JOIN {{ ref("stg__voc_concept") }} AS vc2
        ON vcr.concept_id_2 = vc2.concept_id
       AND vc2.standard_concept = 'S'
       AND vc2.invalid_reason IS NULL

    LEFT JOIN {{ ref("int__lk_meas_unit_concept") }} AS uc
        ON src.valueuom = uc.source_code
)

SELECT
    CAST(hash(measurement_group_id, row_discriminator) >> 1 AS BIGINT) AS measurement_id,

    subject_id,
    hadm_id,
    stay_id,
    provider_id,
    start_datetime,
    32817 AS type_concept_id,

    itemid,
    source_code,
    source_label,

    vocabulary_id,
    source_domain_id,
    source_concept_id,
    target_domain_id,
    target_concept_id,

    CAST(valuenum AS TEXT) AS value_source_value,
    0 AS value_as_concept_id,

    CASE
        WHEN itemid = 227488 THEN -valuenum
        ELSE valuenum
    END AS value_as_number,

    valueuom AS unit_source_value,
    COALESCE(unit_target_concept_id, 0) AS unit_concept_id,
    COALESCE(unit_source_concept_id, 0) AS unit_source_concept_id,

    CONCAT('meas.', unit_id) AS unit_id,
    load_table_id,
    CAST(hash(measurement_group_id, row_discriminator) >> 1 AS BIGINT) AS load_row_id,
    trace_id

FROM expanded
