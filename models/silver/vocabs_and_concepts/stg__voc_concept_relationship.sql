select
    cast(vr.concept_id_1 as integer) as concept_id_1,
    cast(vr.concept_id_2 as integer) as concept_id_2,
    vr.relationship_id,
    try_cast(
        strptime(cast(vr.valid_start_date as varchar), '%Y%m%d') as date
    ) as valid_start_date,
    try_cast(
        strptime(cast(vr.valid_end_date as varchar), '%Y%m%d') as date
    ) as valid_end_date,
    vr.invalid_reason

from {{ source("athena_vocabulary", "CONCEPT_RELATIONSHIP") }} as vr
inner join {{ ref("stg__voc_concept") }} vc1 on vc1.concept_id = vr.concept_id_1
inner join {{ ref("stg__voc_concept") }} vc2 on vc2.concept_id = vr.concept_id_2

union all

select
    tcr.concept_id_1 as concept_id_1,
    tcr.concept_id_2 as concept_id_2,
    tcr.relationship_id as relationship_id,
    tcr.valid_start_date as valid_start_date,
    tcr.valid_end_date as valid_end_date,
    tcr.invalid_reason as invalid_reason
from {{ ref("stg__custom_concept_relationship") }} tcr
