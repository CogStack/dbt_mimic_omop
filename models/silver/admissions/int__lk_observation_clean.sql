SELECT
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    'Insurance' AS source_code,
    46235654 AS target_concept_id,
    src.admittime AS start_datetime,
    src.dischtime AS end_datetime,
    src.insurance AS value_as_string,
    'mimiciv_obs_insurance' AS source_vocabulary_id,
    src.admit_provider_id AS provider_id,
    --
    'admissions.insurance' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(src.load_row_id, 'admissions.insurance') >> 1 AS BIGINT) AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("stg__admissions") }} AS src
WHERE
    src.insurance IS NOT NULL

UNION ALL

SELECT
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    'Marital status' AS source_code,
    40766231 AS target_concept_id,
    src.admittime AS start_datetime,
    src.dischtime AS end_datetime,
    src.marital_status AS value_as_string,
    'mimiciv_obs_marital' AS source_vocabulary_id,
    src.admit_provider_id AS provider_id,
    --
    'admissions.marital_status' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(src.load_row_id, 'admissions.marital_status') >> 1 AS BIGINT) AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("stg__admissions") }} AS src
WHERE
    src.marital_status IS NOT NULL

UNION ALL

SELECT
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    'Language' AS source_code,
    40758030 AS target_concept_id,
    src.admittime AS start_datetime,
    src.dischtime AS end_datetime,
    src.language AS value_as_string,
    'mimiciv_obs_language' AS source_vocabulary_id,
    src.admit_provider_id AS provider_id,
    --
    'admissions.language' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(src.load_row_id, 'admissions.language') >> 1 AS BIGINT) AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("stg__admissions") }} AS src
WHERE
    src.language IS NOT NULL

UNION ALL

SELECT
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    src.drg_code AS source_code,
    4296248 AS target_concept_id,
    COALESCE(adm.edregtime, adm.admittime) AS start_datetime,
    adm.dischtime AS end_datetime,
    src.description AS value_as_string,
    'mimiciv_obs_drgcodes' AS source_vocabulary_id,
    adm.admit_provider_id AS provider_id,
    --
    'drgcodes.description' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(
        adm.load_row_id,
        src.drg_code,
        src.description
    ) >> 1 AS BIGINT) AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("stg__drgcodes") }} AS src -- drg
INNER JOIN
    {{ ref("stg__admissions") }} AS adm
        ON src.hadm_id = adm.hadm_id
WHERE
    src.description IS NOT NULL