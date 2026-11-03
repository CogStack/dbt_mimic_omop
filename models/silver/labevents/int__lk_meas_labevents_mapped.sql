with lk_meas_labevents_clean AS (
SELECT
    CAST(hash(src.subject_id, src.charttime, src.hadm_id, src.itemid, src.load_row_id) >> 1 AS BIGINT) AS measurement_id, 
    src.subject_id AS subject_id,
    src.charttime AS start_datetime, -- measurement_datetime
    src.hadm_id AS hadm_id,
    src.itemid AS itemid,
    src.order_provider_id AS order_provider_id,
    src.value AS value, -- value_source_value
    regexp_extract(src.value, '^(<=|>=|>|<|=|)', 1) AS value_operator,
    NULLIF(
        regexp_extract(TRIM(src.value), '([-]?[0-9]+(?:\.[0-9]+)?)', 1),
        ''
    ) AS value_number,
    NULLIF(TRIM(src.valueuom), '') AS valueuom, -- unit_source_value
    src.ref_range_lower AS ref_range_lower,
    src.ref_range_upper AS ref_range_upper,
    --
    'labevents' AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("stg__labevents") }} AS src
INNER JOIN
    {{ ref("stg__d_labitems") }} AS dlab
        ON src.itemid = dlab.itemid
), lk_meas_labevents_hadm_id AS (
SELECT
    src.trace_id AS event_trace_id, 
    adm.hadm_id AS hadm_id,
    ROW_NUMBER() OVER (
        PARTITION BY src.trace_id
        ORDER BY adm.start_datetime, adm.hadm_id
    ) AS row_num
FROM  
    lk_meas_labevents_clean AS src
INNER JOIN 
    {{ ref("int__lk_admissions_clean") }} AS adm
        ON adm.subject_id = src.subject_id
        AND src.start_datetime BETWEEN adm.start_datetime AND adm.end_datetime
WHERE
    src.hadm_id IS NULL
)

SELECT
    src.measurement_id AS measurement_id,
    src.subject_id AS subject_id,
    COALESCE(src.hadm_id, hadm.hadm_id) AS hadm_id,
    CAST(src.start_datetime AS DATE) AS date_id,
    src.start_datetime AS start_datetime,
    src.itemid AS itemid,
    CAST(src.itemid AS TEXT) AS source_code,
    labc.source_vocabulary_id AS source_vocabulary_id,
    labc.source_concept_id AS source_concept_id,
    COALESCE(labc.target_domain_id, 'Measurement') AS target_domain_id,
    labc.target_concept_id AS target_concept_id,
    src.valueuom AS unit_source_value,
    CASE
        WHEN src.valueuom IS NOT NULL 
        THEN COALESCE(uc.target_concept_id, 0)
        ELSE NULL
    END AS unit_concept_id,
    CASE
        WHEN src.valueuom IS NOT NULL
        THEN COALESCE(uc.source_concept_id, 0)
        ELSE NULL
    END AS unit_source_concept_id,
    src.value_operator AS operator_source_value,
    opc.target_concept_id AS operator_concept_id,
    src.value AS value_source_value,
    src.value_number AS value_as_number,
    CAST(NULL AS INTEGER) AS value_as_concept_id,
    src.ref_range_lower AS range_low,
    src.ref_range_upper AS range_high,
    src.order_provider_id AS provider_id,
    CONCAT('meas.', src.unit_id) AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM  
    lk_meas_labevents_clean AS src
INNER JOIN 
    {{ ref("int__lk_meas_d_labitems_concept") }} AS labc
        ON labc.itemid = src.itemid
LEFT JOIN 
    {{ ref("int__lk_meas_operator_concept") }} AS opc
        ON opc.source_code = src.value_operator
LEFT JOIN 
    {{ ref("int__lk_meas_unit_concept") }} AS uc
        ON uc.source_code = src.valueuom
LEFT JOIN 
    lk_meas_labevents_hadm_id AS hadm
        ON hadm.event_trace_id = src.trace_id
        AND hadm.row_num = 1