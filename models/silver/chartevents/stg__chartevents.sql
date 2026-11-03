SELECT
	subject_id                                            AS subject_id,
	hadm_id                                               AS hadm_id,
	stay_id                                               AS stay_id,
	caregiver_id                                          AS caregiver_id,
	itemid                                                AS itemid,
	charttime                                             AS charttime,
	value                                                 AS value,
	CAST(valuenum AS float)                               AS valuenum,
	valueuom                                              AS valueuom,
	'chartevents'                                         AS load_table_id,
	 -- this stil results in duplicates
	CAST(hash(subject_id, hadm_id, stay_id, caregiver_id, charttime, itemid, value, valuenum, valueuom) >> 1 AS BIGINT) AS load_row_id,
	json_object(
        'subject_id', subject_id, 
        'hadm_id', hadm_id, 
        'stay_id', stay_id, 
        'charttime', charttime)                           AS trace_id
FROM
	{{ source("mimic", "chartevents") }}