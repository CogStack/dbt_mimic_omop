SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    stay_id                             AS stay_id,
	caregiver_id                        AS caregiver_id,
    itemid                              AS itemid,
    starttime                           AS starttime,
    endtime                             AS endtime,
    value                               AS value,
    CAST(0 AS INTEGER)                  AS cancelreason,
    'procedureevents'                   AS load_table_id,
    CAST(hash(subject_id, hadm_id, starttime) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id, 'starttime', starttime)::text AS trace_id
FROM
    {{ source("mimic", "procedureevents") }}