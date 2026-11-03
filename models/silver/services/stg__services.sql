select     
    subject_id                          AS subject_id,
    hadm_id                             AS hadm_id,
    transfertime                        AS transfertime,
    prev_service                        AS prev_service,
    curr_service                        AS curr_service,
    'services'                          AS load_table_id,
    CAST(hash(
        subject_id,
        hadm_id,
        transfertime
    ) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 
        'hadm_id', hadm_id, 
        'transfertime', transfertime)::text AS trace_id
from {{ source("mimic", "services") }}