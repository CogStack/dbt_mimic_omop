select
    cast(concept_id as integer) as concept_id,
    concept_synonym_name,
    cast(language_concept_id as integer) as language_concept_id
from {{ source("athena_vocabulary", "CONCEPT_SYNONYM") }}
