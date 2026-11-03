-- has some duplicates, this handles it
SELECT *
FROM (
    SELECT
        nlp_cui,
        nlp_pretty_name,
        CAST(nlp_end AS INT) AS nlp_end,
        nlp_types,
        nlp_detected_name,
        nlp_meta_anns_Presence_confidence,
        nlp_meta_anns_Presence_name,
        nlp_meta_anns_Presence_value,
        nlp_meta_anns_Time_confidence,
        nlp_meta_anns_Time_name,
        nlp_meta_anns_Time_value,
        nlp_meta_anns_Subject_confidence,
        nlp_meta_anns_Subject_name,
        nlp_meta_anns_Subject_value,
        service_version,
        CAST(nlp_start AS INT) AS nlp_start,
        nlp_source_value,
        nlp_id,
        meta_note_id,
        service_model,
        meta_subject_id,
        nlp_acc,
        nlp_type_ids,
        nlp_context_similarity,
        nlp_ontologies,
        timestamp,
        CAST(hash(nlp_id, meta_note_id) >> 1 AS BIGINT) AS load_row_id,

        ROW_NUMBER() OVER (
            PARTITION BY nlp_id, meta_note_id
            ORDER BY timestamp DESC, nlp_source_value  -- choose deterministically
        ) AS rn
    FROM {{ source('mimic', 'radiology_annotations') }}
) t
WHERE rn = 1
