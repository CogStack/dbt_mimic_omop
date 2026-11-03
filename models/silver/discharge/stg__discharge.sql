SELECT
    note_id AS note_id,
    subject_id AS subject_id,
    hadm_id AS hamd_id,
    note_type AS note_type,
    note_seq AS note_seq,
    charttime AS charttime,
    storetime AS storetime,
    text AS text,
    'discharge' AS load_table_id,
    CAST(hash(note_id, subject_id, hadm_id) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id)::text AS trace_id
FROM
    {{ source('mimic', 'discharge') }}