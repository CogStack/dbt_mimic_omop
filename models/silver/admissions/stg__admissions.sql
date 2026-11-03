SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    admittime                           AS admittime,
    dischtime                           AS dischtime,
    deathtime                           AS deathtime,
    admission_type                      AS admission_type,
	admit_provider_id                   AS admit_provider_id,
    admission_location                  AS admission_location,
    discharge_location                  AS discharge_location,
    race                                AS race,
    edregtime                           AS edregtime,
	edouttime                           AS edouttime,
    insurance                           AS insurance,
    marital_status                      AS marital_status,
    language                            AS language,
	hospital_expire_flag                AS hospital_expire_flag,
	'admissions'                        AS load_table_id,
	CAST(hash(hadm_id, subject_id) >> 1 AS BIGINT) AS load_row_id,
	json_object(
        'subject_id', subject_id,
        'hadm_id', hadm_id
    )::text                             AS trace_id
from {{ source("mimic", "admissions") }}
