WITH notes_src AS (

    SELECT
        note_id,
        subject_id,
        hamd_id,
        charttime,
        text,
        706531 AS note_class_concept_id,
        'DISCHARGE SUMMARY' AS note_title,
        'Discharge summary' AS note_source_value
    FROM {{ ref('stg__discharge') }}

    UNION ALL

    SELECT
        note_id,
        subject_id,
        hamd_id,
        charttime,
        text,
        706371 AS note_class_concept_id,
        'RADIOLOGY REPORT' AS note_title,
        'Report' AS note_source_value
    FROM {{ ref('stg__radiology') }}

),

-- this is combat memory issues
notes_src_small AS (
    SELECT
        note_id,
        subject_id,
        hamd_id
    FROM notes_src
),

-- to stop duplicates when multiple visits match we
-- sort by the earliest visit_occurence
notes_with_visit AS (
    SELECT
        src.note_id AS raw_note_id,
        per.person_id AS person_id,
        vo.visit_occurrence_id AS visit_occurrence_id,
        vd.visit_detail_id AS visit_detail_id,
        ROW_NUMBER() OVER (
            PARTITION BY src.note_id
            ORDER BY vo.visit_start_datetime ASC NULLS LAST, vo.visit_occurrence_id ASC, vd.visit_detail_id ASC NULLS LAST
        ) AS rn
    FROM notes_src_small AS src
    -- this is an inner join as some notes have subject_ids not in person table
    -- this is due to mimic-iv-note being ver 2.2 (latest)
    -- and mimic-iv being 3.1 (latest)
    INNER JOIN {{ ref('person') }} AS per
        ON src.subject_id::text = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} AS vo
        ON src.hamd_id::text = split_part(vo.visit_source_value, '|', 2)
    LEFT JOIN {{ ref('visit_detail') }} AS vd
        ON vo.visit_occurrence_id = vd.visit_occurrence_id
)


SELECT
    ids.note_id AS note_id,
    nwv.person_id,
    src.charttime::date AS note_date,
    src.charttime AS note_datetime,
    32817 AS note_type_concept_id,
    src.note_class_concept_id,
    src.note_title,
    src.text AS note_text,
    32766 AS encoding_concept_id,
    4180186 AS language_concept_id,
    NULL AS provider_id,
    nwv.visit_occurrence_id,
    nwv.visit_detail_id,
    src.note_source_value,
    NULL AS note_event_id,
    NULL AS note_event_field_concept_id
FROM notes_with_visit nwv
JOIN notes_src src
    ON nwv.raw_note_id = src.note_id
JOIN {{ ref('int__note_id_map') }} ids
    ON ids.raw_note_id = nwv.raw_note_id
WHERE nwv.rn = 1
