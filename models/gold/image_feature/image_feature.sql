-- MI-CDM Image_feature table
-- Captures features derived from imaging studies with full provenance tracking
-- Each row represents a CheXpert-derived finding for a specific image
-- Based on OHDSI Medical Imaging CDM extension specification

{{
    config(
        tags=['mimic_cxr', 'mi_cdm']
    )
}}

SELECT
    -- Primary key
    src.image_feature_id                        AS image_feature_id,
    
    -- Foreign key to image_occurrence
    CAST(hash(src.dicom_id) >> 1 AS BIGINT)                          AS image_occurrence_id,
    
    -- Feature concept: SNOMED concept for the finding
    src.finding_concept_id                      AS image_feature_concept_id,
    
    -- Feature type: indicates how the feature was derived
    -- 32879 = "Registry-based algorithm" (NLP-derived)
    32879                                       AS image_feature_type_concept_id,
    
    -- Feature value
    -- 1.0 = positive, 0.0 = negative, -1.0 = uncertain
    src.finding_value                           AS value_as_number,
    
    -- Value interpretation
    CASE 
        WHEN src.finding_value = 1.0 THEN 'Positive'
        WHEN src.finding_value = 0.0 THEN 'Negative'
        WHEN src.finding_value = -1.0 THEN 'Uncertain'
        ELSE 'Unknown'
    END                                         AS value_as_concept_name,
    
    -- Algorithm provenance
    'CheXpert'                                  AS alg_system,
    NULL::TIMESTAMP                             AS alg_datetime,
    
    -- Source values for traceability
    src.finding_name                            AS feature_source_value,
    src.study_id                                AS study_id,
    src.subject_id                              AS subject_id

FROM {{ ref("int__imaging_features_pivoted") }} src
-- Only include rows where we have a valid image link
WHERE src.dicom_id IS NOT NULL
