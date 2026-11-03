select * replace (cast(vocabulary_concept_id as integer) as vocabulary_concept_id)
from {{ source("athena_vocabulary", "VOCABULARY") }}
where vocabulary_concept_id < 2000000000
