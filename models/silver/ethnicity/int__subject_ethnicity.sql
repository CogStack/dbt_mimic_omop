SELECT DISTINCT
    subject_id,
    FIRST_VALUE(race) OVER (
        PARTITION BY subject_id 
        ORDER BY admittime ASC, hadm_id ASC) AS ethnicity_first
FROM
    {{ ref("stg__admissions") }}