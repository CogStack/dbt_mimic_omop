with lk_specimen_clean as (
SELECT DISTINCT
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    src.provider_id AS provider_id,
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime,
    src.spec_itemid AS spec_itemid, -- d_micro.itemid, type of specimen taken
    --
    'micro.specimen' AS unit_id,
    src.load_table_id AS load_table_id,
    0 AS load_row_id,
    cr.trace_id_spec AS trace_id -- trace_id for specimen
FROM
    {{ ref("int__lk_meas_organism_clean") }} AS src
INNER JOIN
    {{ ref("int__lk_micro_cross_ref") }} AS cr
        ON src.trace_id = cr.trace_id_spec
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(src.subject_id, src.start_datetime, src.end_datetime, src.spec_itemid, src.provider_id)) AS INTEGER) AS specimen_id,
    src.subject_id AS subject_id,
    COALESCE(src.hadm_id, hadm.hadm_id) AS hadm_id,
    CAST(src.start_datetime AS DATE) AS date_id,
    32856 AS type_concept_id, -- Lab
    src.start_datetime AS start_datetime,
    src.end_datetime AS end_datetime,
    src.spec_itemid AS spec_itemid,
    mc.source_code AS source_code,
    mc.source_vocabulary_id AS source_vocabulary_id,
    mc.source_concept_id AS source_concept_id,
    COALESCE(mc.target_domain_id, 'Specimen') AS target_domain_id,
    mc.target_concept_id AS target_concept_id,
    src.provider_id AS provider_id,
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    lk_specimen_clean AS src
INNER JOIN
    {{ ref("int__lk_d_micro_concept") }} AS mc
        ON src.spec_itemid = mc.itemid
LEFT JOIN
    {{ ref("int__lk_micro_hadm_id") }} AS hadm
        ON hadm.event_trace_id = src.trace_id
        AND hadm.row_num = 1