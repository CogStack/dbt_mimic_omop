SELECT
    subject_id  AS subject_id,
    hadm_id     AS hadm_id,
    stay_id     AS stay_id,
    caregiver_id AS caregiver_id,
    charttime   AS charttime,
    storetime   AS storetime,
    itemid      AS itemid,
    value       AS value,
    valueuom    AS valueuom,
    'outputevents'                       AS load_table_id,
    CAST(hash(subject_id, hadm_id, stay_id, caregiver_id, charttime, itemid) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id, 'stay_id', stay_id, 'charttime', charttime)::text AS trace_id
FROM
    {{ source("mimic", "outputevents") }}