SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
	drg_type                            AS drg_type,
    drg_code                            AS drg_code,
    description                         AS description,
	drg_severity                        AS drg_severity,
	drg_mortality                       AS drg_mortality,
    'drgcodes'                          AS load_table_id,
    CAST(hash(subject_id, hadm_id, COALESCE(drg_code, '')) >> 1 AS BIGINT) AS load_row_id,
    json_object('subject_id', subject_id, 'hadm_id', hadm_id, 'drg_code', COALESCE(drg_code, ''))::text AS trace_id
FROM
    {{ source("mimic", "drgcodes") }}