SELECT 
    src.visit_detail_id AS visit_detail_id,
    src.subject_id AS subject_id,
    src.hadm_id AS hadm_id,
    src.date_id AS date_id,
    src.start_datetime AS start_datetime,
    COALESCE(
        src.end_datetime,
        LEAD(src.start_datetime) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id
            ORDER BY src.start_datetime ASC, src.visit_detail_id ASC
        ),
        vis.end_datetime
    ) AS end_datetime,
    src.source_value AS source_value,
    src.provider_id AS provider_id,
    --
    src.current_location AS current_location,
    LAG(src.visit_detail_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
        ORDER BY src.start_datetime ASC, src.visit_detail_id ASC
    ) AS preceding_visit_detail_id,
    COALESCE(
        LAG(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id -- double-check if chains follow each other or intercept
            ORDER BY src.start_datetime ASC, src.visit_detail_id ASC
        ),
        vis.admission_location
    ) AS admission_location,
    COALESCE(
        LEAD(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
            ORDER BY src.start_datetime ASC, src.visit_detail_id ASC
        ),
        vis.discharge_location
    ) AS discharge_location,
    --
    src.unit_id AS unit_id,
    src.load_table_id AS load_table_id,
    src.load_row_id AS load_row_id,
    src.trace_id AS trace_id
FROM
    {{ ref("int__lk_visit_detail_clean") }} AS src
LEFT JOIN
    {{ ref("int__lk_visit_clean") }} AS vis
        ON src.subject_id = vis.subject_id
        AND (
            src.hadm_id = vis.hadm_id
            OR (src.hadm_id IS NULL AND src.date_id = vis.date_id)
        )