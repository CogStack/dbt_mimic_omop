SELECT DISTINCT
    src.subject_id, 
    FIRST_VALUE(src.deathtime) OVER (
        PARTITION BY src.subject_id 
        ORDER BY src.admittime ASC, src.hadm_id ASC
    ) AS deathtime, 
    FIRST_VALUE(src.dischtime) OVER (
        PARTITION BY src.subject_id 
        ORDER BY src.admittime ASC, src.hadm_id ASC
    ) AS dischtime,
    32817 AS type_concept_id, -- OMOP4976890 EHR
    --
    'admissions' AS unit_id,
    src.load_table_id,
    FIRST_VALUE(src.load_row_id) OVER (
        PARTITION BY src.subject_id 
        ORDER BY src.admittime ASC, src.hadm_id ASC
    ) AS load_row_id,
    FIRST_VALUE(src.trace_id) OVER (
        PARTITION BY src.subject_id 
        ORDER BY src.admittime ASC, src.hadm_id ASC
    ) AS trace_id
FROM 
    {{  ref("stg__admissions")  }} AS src
WHERE 
    src.deathtime IS NOT NULL