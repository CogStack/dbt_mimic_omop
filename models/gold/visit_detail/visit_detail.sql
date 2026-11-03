SELECT
    src.visit_detail_id AS visit_detail_id,
    per.person_id AS person_id,
    COALESCE(vdc.target_concept_id, 0) AS visit_detail_concept_id,
                                       -- see source value in care_site.care_site_source_value
    CAST(src.start_datetime AS DATE) AS visit_detail_start_date,
    src.start_datetime AS visit_detail_start_datetime,
    CAST(src.end_datetime AS DATE) AS visit_detail_end_date,
    src.end_datetime AS visit_detail_end_datetime,
    32817 AS visit_detail_type_concept_id,   -- EHR   Type Concept    Standard
    prov.provider_id AS provider_id,
    cs.care_site_id AS care_site_id,
    src.source_value AS visit_detail_source_value,
    COALESCE(vdc.source_concept_id, 0) AS visit_detail_source_concept_id,
    CASE
        WHEN src.admission_location IS NOT NULL 
        THEN COALESCE(la.target_concept_id, 0)
        ELSE NULL
    END AS admitted_from_concept_id,
    src.admission_location AS admitted_from_source_value,
    src.discharge_location AS discharged_to_source_value,
    CASE
        WHEN src.discharge_location IS NOT NULL 
        THEN COALESCE(ld.target_concept_id, 0)
        ELSE NULL
    END AS discharged_to_concept_id,
    src.preceding_visit_detail_id AS preceding_visit_detail_id,
    CAST(NULL AS INTEGER) AS parent_visit_detail_id,
    vis.visit_occurrence_id AS visit_occurrence_id
FROM
    {{ ref("int__lk_visit_detail_prev_next") }} AS src
INNER JOIN
    {{ ref("person")}} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref("visit_occurrence") }} AS vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|',
                COALESCE(CAST(src.hadm_id AS TEXT), CAST(src.date_id AS TEXT)))
LEFT JOIN
    {{ ref("care_site") }} AS cs
        ON cs.care_site_source_value = src.current_location
LEFT JOIN
    {{ ref("int__lk_visit_concept") }} AS vdc
        ON vdc.source_code = src.current_location
LEFT JOIN
    {{ ref("int__lk_visit_concept") }} AS la
        ON la.source_code = src.admission_location
LEFT JOIN
    {{ ref("int__lk_visit_concept") }} AS ld
        ON ld.source_code = src.discharge_location
LEFT JOIN
    {{ ref("provider") }} AS prov
        ON src.provider_id = prov.provider_id