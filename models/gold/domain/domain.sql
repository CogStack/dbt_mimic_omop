select
    domain_id,
    domain_name,
    cast(domain_concept_id as integer) as domain_concept_id
from {{ source("athena_vocabulary", "DOMAIN") }}
