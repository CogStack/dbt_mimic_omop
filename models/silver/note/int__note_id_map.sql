-- 32-bit note_id for each MIMIC note_id (e.g. 10000032-DS-21), numbered in note_id order so reruns give the same ids;
-- shared by note and note_nlp
SELECT
    note_id AS raw_note_id,
    CAST(ROW_NUMBER() OVER (ORDER BY note_id) AS INTEGER) AS note_id
FROM (
    SELECT note_id FROM {{ ref('stg__discharge') }}
    UNION ALL
    SELECT note_id FROM {{ ref('stg__radiology') }}
)
