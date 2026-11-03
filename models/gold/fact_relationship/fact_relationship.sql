-- measurement ids in the silver models are 64-bit hashes; int__measurement_id_map gives their 32-bit ids
WITH spec_org AS (
    SELECT
        spec.specimen_id,
        ids.measurement_id
    FROM {{ ref('int__lk_specimen_mapped') }} spec
    JOIN {{ ref('int__lk_meas_organism_mapped') }} org
        ON org.trace_id_spec = spec.trace_id
    JOIN {{ ref('int__measurement_id_map') }} ids
        ON ids.hash_id = org.measurement_id
),
org_ab AS (
    SELECT
        org_ids.measurement_id AS org_measurement_id,
        ab_ids.measurement_id AS ab_measurement_id
    FROM {{ ref('int__lk_meas_organism_mapped') }} org
    JOIN {{ ref('int__lk_meas_ab_mapped') }} ab
        ON ab.trace_id_org = org.trace_id
    JOIN {{ ref('int__measurement_id_map') }} org_ids
        ON org_ids.hash_id = org.measurement_id
    JOIN {{ ref('int__measurement_id_map') }} ab_ids
        ON ab_ids.hash_id = ab.measurement_id
)

SELECT
    36                AS domain_concept_id_1,
    specimen_id       AS fact_id_1,
    21                AS domain_concept_id_2,
    measurement_id    AS fact_id_2,
    32669             AS relationship_concept_id
FROM spec_org

UNION ALL

SELECT
    21                AS domain_concept_id_1,
    measurement_id    AS fact_id_1,
    36                AS domain_concept_id_2,
    specimen_id       AS fact_id_2,
    32668             AS relationship_concept_id
FROM spec_org

UNION ALL

SELECT
    21                AS domain_concept_id_1,
    org_measurement_id AS fact_id_1,
    21                AS domain_concept_id_2,
    ab_measurement_id AS fact_id_2,
    581436            AS relationship_concept_id
FROM org_ab

UNION ALL

SELECT
    21                AS domain_concept_id_1,
    ab_measurement_id AS fact_id_1,
    21                AS domain_concept_id_2,
    org_measurement_id AS fact_id_2,
    581437            AS relationship_concept_id
FROM org_ab
