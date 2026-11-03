SELECT
subject_id::INTEGER    AS subject_id,
hadm_id::INTEGER       AS hadm_id,
transfer_id::INTEGER   AS transfer_id,
eventtype::VARCHAR     AS eventtype,
careunit::VARCHAR      AS careunit,
intime::TIMESTAMP      AS intime,
outtime::TIMESTAMP     AS outtime,
'transfers'            AS load_table_id,
CAST(hash(subject_id, hadm_id, transfer_id) >> 1 AS BIGINT)       AS load_row_id,
json_object(
    'subject_id', subject_id,
    'hadm_id', hadm_id,
    'transfer_id', transfer_id
)::text               AS trace_id
FROM {{ source("mimic", "transfers") }}