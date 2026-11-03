SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
	chartdate                           AS chartdate,
    hcpcs_cd                            AS hcpcs_cd,
    seq_num                             AS seq_num,
    short_description                   AS short_description,
    'hcpcsevents'                       AS load_table_id,
    CAST(hash(subject_id, hadm_id, hcpcs_cd, seq_num) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id, 'hcpcs_cd', hcpcs_cd, 'seq_num', seq_num)::text AS trace_id
FROM
    {{ source("mimic", "hcpcsevents") }}