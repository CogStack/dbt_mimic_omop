select
    relationship_id,
    relationship_name,
    cast(is_hierarchical as varchar) as is_hierarchical,
    cast(defines_ancestry as varchar) as defines_ancestry,
    reverse_relationship_id,
    cast(relationship_concept_id as integer) as relationship_concept_id
from {{ source("athena_vocabulary", "RELATIONSHIP") }}
