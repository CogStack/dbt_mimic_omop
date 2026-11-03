SELECT
    subject_id      AS subject_id,
    hadm_id         AS hadm_id,
    seq_num         AS seq_num,
    icd_code        AS icd_code,
    icd_version     AS icd_version,
    'diagnoses_icd'                     AS load_table_id,
    CAST(hash(hadm_id, seq_num) >> 1 AS BIGINT) AS load_row_id,
    json_object('hadm_id', hadm_id, 'seq_num', seq_num)::text AS trace_id
FROM
    {{ source("mimic", "diagnoses_icd") }}