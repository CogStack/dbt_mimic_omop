SELECT
    src.trace_id_ab AS event_trace_id,
    adm.hadm_id AS hadm_id,
    ROW_NUMBER() OVER (
        PARTITION BY src.trace_id_ab
        ORDER BY adm.start_datetime, adm.hadm_id
    ) AS row_num
FROM  
    {{ ref("int__lk_micro_cross_ref") }} AS src
INNER JOIN 
    {{ ref("int__lk_admissions_clean") }} AS adm
        ON adm.subject_id = src.subject_id
        AND src.start_datetime BETWEEN adm.start_datetime AND adm.end_datetime
WHERE
    src.hadm_id IS NULL