-- Staging model for MIMIC-CXR DICOM metadata
-- Contains extracted DICOM header fields for each image
-- Column names match MIMIC-CXR-JPG v2.1.0 schema

{{
    config(
        tags=['mimic_cxr']
    )
}}

SELECT
    dicom_id::VARCHAR                                       AS dicom_id,
    subject_id::BIGINT                                      AS subject_id,
    study_id::BIGINT                                        AS study_id,
    -- Parse StudyDate from YYYYMMDD integer format to DATE
    TRY_CAST(
        SUBSTR("StudyDate"::VARCHAR, 1, 4) || '-' ||
        SUBSTR("StudyDate"::VARCHAR, 5, 2) || '-' ||
        SUBSTR("StudyDate"::VARCHAR, 7, 2) AS DATE
    )                                                       AS study_date,
    -- StudyTime as string (HHMMSS.fraction format)
    "StudyTime"::VARCHAR                                    AS study_time,
    "ViewPosition"::VARCHAR                                 AS view_position,
    "Rows"::INTEGER                                         AS image_rows,
    "Columns"::INTEGER                                      AS image_columns,
    "PerformedProcedureStepDescription"::VARCHAR            AS procedure_description,
    "ProcedureCodeSequence_CodeMeaning"::VARCHAR            AS procedure_code_meaning,
    "ViewCodeSequence_CodeMeaning"::VARCHAR                 AS view_code_meaning,
    "PatientOrientationCodeSequence_CodeMeaning"::VARCHAR   AS patient_orientation,
    -- Derive modality from procedure description (CR or DX for chest x-rays)
    CASE 
        WHEN "PerformedProcedureStepDescription" LIKE '%PORTABLE%' THEN 'DX'
        ELSE 'CR'
    END                                                     AS modality,
    -- Body part is always chest for MIMIC-CXR
    'CHEST'                                                 AS body_part_examined,
    -- Traceability
    'mimic_cxr_metadata'                                    AS load_table_id,
    CAST(hash(dicom_id) >> 1 AS BIGINT)                                          AS load_row_id,
    json_object(
        'dicom_id', dicom_id,
        'study_id', study_id
    )::TEXT                                                 AS trace_id
FROM {{ source("mimic_cxr", "mimic_cxr_metadata") }}
