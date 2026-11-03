-- MI-CDM Image_occurrence table
-- Represents imaging events at the DICOM image level
-- Links to Person, Visit_occurrence, and provides image file paths
-- Based on OHDSI Medical Imaging CDM extension specification

{{
    config(
        tags=['mimic_cxr', 'mi_cdm']
    )
}}

SELECT
    -- Primary key: hash of dicom_id for stable ID
    CAST(hash(src.dicom_id) >> 1 AS BIGINT)                          AS image_occurrence_id,
    
    -- Foreign keys to OMOP CDM
    src.person_id                               AS person_id,
    src.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS procedure_occurrence_id,
    
    -- Image occurrence dates
    src.study_date                              AS image_occurrence_date,
    CASE 
        WHEN src.study_time IS NOT NULL 
        THEN CAST(src.study_date AS TIMESTAMP) + 
             TRY_CAST(
                 SUBSTR(src.study_time, 1, 2) || ':' || 
                 SUBSTR(src.study_time, 3, 2) || ':' || 
                 COALESCE(SUBSTR(src.study_time, 5, 2), '00') 
                 AS INTERVAL
             )
        ELSE CAST(src.study_date AS TIMESTAMP)
    END                                         AS image_occurrence_datetime,
    
    -- Modality concept: CR (Computed Radiography) or DX (Digital X-ray)
    -- OMOP concept_id for modality (using SNOMED)
    CASE 
        WHEN src.modality = 'CR' THEN 4013      -- Computed Radiography
        WHEN src.modality = 'DX' THEN 4014      -- Digital X-ray
        ELSE 0
    END                                         AS modality_concept_id,
    
    -- Anatomic site: Thorax/Chest
    4218106                                     AS anatomic_site_concept_id,  -- SNOMED: Thoracic structure
    
    -- Type concept: EHR-derived
    32817                                       AS image_type_concept_id,     -- EHR
    
    -- DICOM UIDs for provenance (not available in MIMIC-CXR-JPG metadata)
    NULL::VARCHAR                               AS image_study_uid,
    NULL::VARCHAR                               AS image_series_uid,
    
    -- Image dimensions
    src.image_rows                              AS image_rows,
    src.image_columns                           AS image_columns,
    
    -- File paths for image retrieval
    src.local_path                              AS local_path,
    src.wadors_uri                              AS wadors_uri,
    
    -- Source values
    src.dicom_id                                AS image_source_value,
    src.view_position                           AS view_position,
    src.modality                                AS modality_source_value,
    src.body_part_examined                      AS anatomic_site_source_value,
    src.procedure_description                   AS procedure_source_value,
    
    -- Metadata
    src.study_id                                AS study_id,
    src.subject_id                              AS subject_id,
    src.data_split                              AS data_split,
    src.view_code_meaning                       AS view_code_meaning,
    src.patient_orientation                     AS patient_orientation

FROM {{ ref("int__imaging_visit_linked") }} src
