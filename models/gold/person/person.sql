-- person can be filtered by patients who have an observation period,
-- but this is not required by the CDM
SELECT
    CAST(p.subject_id AS INTEGER) AS person_id,  -- 32-bit, as many OHDSI tools expect
    CASE
        WHEN p.gender = 'F' THEN 8532  -- FEMALE
        WHEN p.gender = 'M' THEN 8507  -- MALE
        ELSE 0
    END AS gender_concept_id,
    p.anchor_year-p.anchor_age AS year_of_birth,
    NULL AS month_of_birth,
    NULL AS day_of_birth,
    CAST(NULL AS DATETIME) AS birth_datetime,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id <> 'Ethnicity' 
                THEN map_eth.target_concept_id
            ELSE NULL
        END, 0) AS race_concept_id,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id = 'Ethnicity' 
                THEN map_eth.target_concept_id
            ELSE NULL
        END, 0) AS ethnicity_concept_id,
    NULL AS location_id,
    NULL AS provider_id,
    NULL AS care_site_id,
    CAST(p.subject_id AS VARCHAR(50)) AS person_source_value,
    p.gender AS gender_source_value,
    0 AS gender_source_concept_id,
    CASE
        WHEN map_eth.target_vocabulary_id <> 'Ethnicity' 
            THEN eth.ethnicity_first
        ELSE NULL
    END AS race_source_value,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id <> 'Ethnicity' 
                THEN map_eth.source_concept_id
            ELSE NULL
        END, 0) AS race_source_concept_id,
    CASE
        WHEN map_eth.target_vocabulary_id = 'Ethnicity' 
            THEN eth.ethnicity_first
        ELSE NULL
    END AS ethnicity_source_value,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id = 'Ethnicity' 
                THEN map_eth.source_concept_id
            ELSE NULL
        END, 0) AS ethnicity_source_concept_id
FROM 
    {{ ref("stg__patients") }} p
LEFT JOIN 
    {{ ref("int__subject_ethnicity") }} eth 
        ON p.subject_id = eth.subject_id
LEFT JOIN 
    {{ ref("int__lk_pat_ethnicity_concept") }} map_eth
        ON eth.ethnicity_first = map_eth.source_code