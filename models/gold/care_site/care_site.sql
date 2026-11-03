SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(src.source_code)) AS INTEGER) AS care_site_id,
    src.source_code               AS care_site_name,
    vc2.concept_id                AS place_of_service_concept_id,
    1                             AS location_id,  -- hard-coded BIDMC
    src.source_code               AS care_site_source_value,
    src.source_code               AS place_of_service_source_value
FROM 
    {{ ref ("int__lk_trans_careunit_clean") }} AS src
LEFT JOIN
    {{ ref ("stg__voc_concept")}} AS vc
        ON vc.concept_code = src.source_code
        AND vc.vocabulary_id = 'mimiciv_cs_place_of_service' -- gcpt_care_site
LEFT JOIN
    {{ ref ("stg__voc_concept_relationship")}} AS vcr
        ON vc.concept_id = vcr.concept_id_1
        AND vcr.relationship_id = 'Maps to'
LEFT JOIN
    {{ ref ("stg__voc_concept")}} AS vc2
        ON vc2.concept_id = vcr.concept_id_2
        AND vc2.standard_concept = 'S'
        AND vc2.invalid_reason IS NULL