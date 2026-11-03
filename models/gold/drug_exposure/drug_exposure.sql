SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(per.person_id, src.hadm_id, vis.visit_occurrence_id, src.load_row_id, src.target_concept_id)) AS INTEGER) AS drug_exposure_id,
    per.person_id AS person_id,
    src.target_concept_id AS drug_concept_id,
    CAST(src.start_datetime AS DATE) AS drug_exposure_start_date,
    src.start_datetime AS drug_exposure_start_datetime,
    CAST(src.end_datetime AS DATE) AS drug_exposure_end_date,
    src.end_datetime AS drug_exposure_end_datetime,
    CAST(NULL AS DATE) AS verbatim_end_date,
    src.type_concept_id AS drug_type_concept_id,
    CAST(NULL AS VARCHAR(20)) AS stop_reason,
    NULL AS refills,
    CAST(src.quantity AS DOUBLE) AS quantity,
    NULL AS days_supply,
    CAST(NULL AS VARCHAR) AS sig,
    src.route_concept_id AS route_concept_id,
    CAST(NULL AS VARCHAR(50)) AS lot_number,
    prov.provider_id AS provider_id,
    vis.visit_occurrence_id AS visit_occurrence_id,
    CAST(NULL AS INTEGER) AS visit_detail_id,
    src.source_code AS drug_source_value,
    src.source_concept_id AS drug_source_concept_id,
    src.route_source_code AS route_source_value,
    src.dose_unit_source_code AS dose_unit_source_value
FROM
    {{ ref('int__lk_drug_mapped') }} AS src
INNER JOIN
    {{ ref('person') }} AS per
        ON CAST(src.subject_id AS TEXT) = per.person_source_value
INNER JOIN
    {{ ref('visit_occurrence') }} AS vis
        ON vis.visit_source_value =
            CONCAT(CAST(src.subject_id AS TEXT), '|', CAST(src.hadm_id AS TEXT))
LEFT JOIN
    {{ ref('provider') }} AS prov
        ON prov.provider_source_value = CAST(src.provider_id AS TEXT)
WHERE
    src.target_domain_id = 'Drug'