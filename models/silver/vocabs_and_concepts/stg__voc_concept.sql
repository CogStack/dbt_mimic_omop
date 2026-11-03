select
    cast(concept_id as integer) as concept_id,
    concept_name,
    domain_id,
    vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    try_cast(
        strptime(cast(valid_start_date as varchar), '%Y%m%d') as date
    ) as valid_start_date,
    try_cast(
        strptime(cast(valid_end_date as varchar), '%Y%m%d') as date
    ) as valid_end_date,

    invalid_reason
from {{ source("athena_vocabulary", "CONCEPT") }}
where concept_id < 2000000000

UNION ALL

SELECT
    voc.concept_id              AS concept_id,
    voc.concept_name            AS concept_name,
    voc.domain_id               AS domain_id,
    voc.vocabulary_id           AS vocabulary_id,
    voc.concept_class_id        AS concept_class_id,
    voc.standard_concept        AS standard_concept,
    voc.concept_code            AS concept_code,
    voc.valid_start_date        AS valid_start_date,
    voc.valid_end_date          AS valid_end_date,
    voc.invalid_reason          AS invalid_reason
FROM 
    {{ref("stg__custom_concept")}} AS voc