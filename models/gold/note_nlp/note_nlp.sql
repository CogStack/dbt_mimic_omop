WITH all_annotations AS (
    SELECT * FROM {{ ref('stg__discharge_annotations') }}
    UNION ALL
    SELECT * FROM {{ ref('stg__radiology_annotations') }}
),

-- This is quite messy, but there are multiple possible mappings from SNOMED CUIs to standard concepts.
-- This results in exploding rows (200m -> 650m) if we do a simple join.
-- To avoid this, we pre-select only one standard concept per SNOMED CUI based on the following criteria:
-- 1) Prefer mappings where the standard concept is in the same domain as the source concept
-- 2) Prefer mappings where the standard concept is in the same concept class as the source concept
-- 3) If multiple mappings still exist, choose the one with the lowest concept_id (for determinism)
-- This is arbitrary, but it means searching through these results can be done with this mapping.
mapped_concepts AS (
    SELECT
        vc.concept_code,
        vc.concept_id  AS source_concept_id,
        vc2.concept_id AS standard_concept_id
    FROM (
        SELECT concept_id, concept_code, domain_id, concept_class_id
        FROM {{ ref('stg__voc_concept') }}
        WHERE vocabulary_id = 'SNOMED'
          AND invalid_reason IS NULL
    ) vc
    LEFT JOIN {{ ref('stg__voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1
       AND vcr.relationship_id = 'Maps to'
    LEFT JOIN (
        SELECT concept_id, domain_id, concept_class_id
        FROM {{ ref('stg__voc_concept') }}
        WHERE standard_concept = 'S'
          AND invalid_reason IS NULL
    ) vc2
        ON vcr.concept_id_2 = vc2.concept_id
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY vc.concept_code
            ORDER BY
                CASE WHEN vc2.domain_id = vc.domain_id THEN 0 ELSE 1 END, -- prefer mappings of the same domain
                CASE WHEN vc2.concept_class_id = vc.concept_class_id THEN 0 ELSE 1 END, -- prefer mappings of the same domain AND concept class
                vc2.concept_id -- choose the mapping sof the same domain and concept class, BUT the lower concept_id if multiple just for determinism
        ) = 1
)

SELECT
    CAST(hash(src.meta_note_id, src.nlp_id) >> 1 AS BIGINT) AS note_nlp_id,
    ids.note_id                       AS note_id,
    0                                 AS section_concept_id,

    SUBSTRING(
        n.note_text
        FROM GREATEST(1, src.nlp_start - 20)
        FOR GREATEST(
            0,
            LEAST(src.nlp_end + 20, LENGTH(n.note_text))
            - GREATEST(1, src.nlp_start - 20)
        )
    )                                 AS snippet,

    CONCAT(src.nlp_start, ':', src.nlp_end) AS offset,
    src.nlp_source_value                    AS lexical_variant,

    mc.standard_concept_id                 AS note_nlp_concept_id,
    CAST(mc.source_concept_id AS VARCHAR)                   AS note_nlp_source_concept_id,

    CONCAT(src.service_model, src.service_version) AS nlp_system,
    CAST(src.timestamp AS DATE)            AS nlp_date,
    CAST(src.timestamp AS DATETIME)                          AS nlp_datetime,

    CASE
        WHEN src.nlp_meta_anns_Presence_value = 'True'  THEN 'T'
        WHEN src.nlp_meta_anns_Presence_value = 'False' THEN 'F'
        ELSE 'H'
    END                                   AS term_exists,

    src.nlp_meta_anns_Time_value           AS term_temporal,

    'Negation=' ||
        CASE
            WHEN src.nlp_meta_anns_Presence_value = 'False' THEN 'true'
            ELSE 'false'
        END ||
    ';Subject=' || src.nlp_meta_anns_Subject_value AS term_modifiers

FROM all_annotations src
LEFT JOIN mapped_concepts mc
    ON src.nlp_cui = mc.concept_code
LEFT JOIN {{ ref('int__note_id_map') }} ids
    ON ids.raw_note_id = src.meta_note_id
LEFT JOIN {{ ref('note') }} n
    ON n.note_id = ids.note_id
