select
    cast(ancestor_concept_id as integer) as ancestor_concept_id,
    cast(descendant_concept_id as integer) as descendant_concept_id,
    min_levels_of_separation,
    max_levels_of_separation
from {{ source("athena_vocabulary", "CONCEPT_ANCESTOR") }}
