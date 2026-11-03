select
    voc.source_vocabulary_id as vocabulary_id,
    voc.source_vocabulary_id as vocabulary_name,
    'Odysseus generated' as vocabulary_reference,
    cast(null as text) as vocabulary_version,
    cast(
        2110000001
        + row_number() over (order by voc.source_vocabulary_id) as integer
    ) as vocabulary_concept_id,

    voc.load_table_id as load_table_id,
    voc.load_row_id as load_row_id
from {{ ref("stg__custom_vocabulary_dist") }} as voc
