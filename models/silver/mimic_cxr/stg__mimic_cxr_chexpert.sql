-- Staging model for MIMIC-CXR CheXpert labels
-- Contains NLP-derived labels for 14 radiological findings
-- Values: 1.0 (positive), 0.0 (negative), -1.0 (uncertain), NULL (not mentioned)

{{
    config(
        tags=['mimic_cxr']
    )
}}

SELECT
    study_id::BIGINT                    AS study_id,
    subject_id::BIGINT                  AS subject_id,
    -- CheXpert labels (14 categories)
    -- Cast to DOUBLE to handle NULL values properly
    "No Finding"::DOUBLE                AS no_finding,
    "Enlarged Cardiomediastinum"::DOUBLE AS enlarged_cardiomediastinum,
    "Cardiomegaly"::DOUBLE              AS cardiomegaly,
    "Lung Opacity"::DOUBLE              AS lung_opacity,
    "Lung Lesion"::DOUBLE               AS lung_lesion,
    "Edema"::DOUBLE                     AS edema,
    "Consolidation"::DOUBLE             AS consolidation,
    "Pneumonia"::DOUBLE                 AS pneumonia,
    "Atelectasis"::DOUBLE               AS atelectasis,
    "Pneumothorax"::DOUBLE              AS pneumothorax,
    "Pleural Effusion"::DOUBLE          AS pleural_effusion,
    "Pleural Other"::DOUBLE             AS pleural_other,
    "Fracture"::DOUBLE                  AS fracture,
    "Support Devices"::DOUBLE           AS support_devices,
    -- Traceability
    'mimic_cxr_chexpert'                AS load_table_id,
    CAST(hash(study_id) >> 1 AS BIGINT)                      AS load_row_id,
    json_object(
        'study_id', study_id,
        'subject_id', subject_id
    )::TEXT                             AS trace_id
FROM {{ source("mimic_cxr", "mimic_cxr_chexpert") }}
