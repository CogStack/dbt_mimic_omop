-- Intermediate model: Unpivot CheXpert labels from wide to long format
-- Each positive/negative/uncertain finding becomes one row
-- Maps CheXpert labels to SNOMED concept IDs via custom mappings

{{
    config(
        materialized='table',
        tags=['mimic_cxr']
    )
}}

WITH chexpert_long AS (
    -- Unpivot 14 CheXpert columns to long format using UNION ALL
    SELECT study_id, subject_id, 'No Finding' AS finding_name, no_finding AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE no_finding IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Enlarged Cardiomediastinum' AS finding_name, enlarged_cardiomediastinum AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE enlarged_cardiomediastinum IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Cardiomegaly' AS finding_name, cardiomegaly AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE cardiomegaly IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Lung Opacity' AS finding_name, lung_opacity AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE lung_opacity IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Lung Lesion' AS finding_name, lung_lesion AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE lung_lesion IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Edema' AS finding_name, edema AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE edema IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Consolidation' AS finding_name, consolidation AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE consolidation IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Pneumonia' AS finding_name, pneumonia AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE pneumonia IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Atelectasis' AS finding_name, atelectasis AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE atelectasis IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Pneumothorax' AS finding_name, pneumothorax AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE pneumothorax IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Pleural Effusion' AS finding_name, pleural_effusion AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE pleural_effusion IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Pleural Other' AS finding_name, pleural_other AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE pleural_other IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Fracture' AS finding_name, fracture AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE fracture IS NOT NULL
    UNION ALL
    SELECT study_id, subject_id, 'Support Devices' AS finding_name, support_devices AS value FROM {{ ref("stg__mimic_cxr_chexpert") }} WHERE support_devices IS NOT NULL
),

-- Get the first dicom_id per study for linking to image_occurrence
study_to_dicom AS (
    SELECT 
        study_id,
        MIN(dicom_id) AS primary_dicom_id
    FROM {{ ref("stg__mimic_cxr_studies") }}
    GROUP BY study_id
)

SELECT
    cl.study_id,
    cl.subject_id,
    std.primary_dicom_id AS dicom_id,
    cl.finding_name,
    cl.value AS finding_value,
    -- Map finding name to SNOMED concept_id via custom mapping
    COALESCE(cm.target_concept_id, 0) AS finding_concept_id,
    -- Generate unique feature ID
    CAST(hash(cl.study_id || '_' || cl.finding_name) >> 1 AS BIGINT) AS image_feature_id
FROM chexpert_long cl
LEFT JOIN study_to_dicom std
    ON cl.study_id = std.study_id
LEFT JOIN {{ ref("stg__custom_mappings") }} cm
    ON cm.concept_code = cl.finding_name
    AND cm.source_vocabulary_id = 'CheXpert'
