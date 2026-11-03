select
    concept_class_id,
    concept_class_name,
    cast(concept_class_concept_id as integer) as concept_class_concept_id
from {{ source("athena_vocabulary", "CONCEPT_CLASS") }}
