SELECT
    subject_id                          AS subject_id,
    hadm_id                             AS hadm_id,
	seq_num                             AS seq_num,
	chartdate                           AS chartdate,
    icd_code        AS icd_code,
    icd_version     AS icd_version,
    'procedures_icd'                    AS load_table_id,
    CAST(hash(subject_id, hadm_id, icd_code, icd_version) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id, 'icd_code', icd_code, 'icd_version', icd_version)::text AS trace_id
FROM
    {{ source("mimic", "procedures_icd") }}