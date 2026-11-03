select
    cast(drug_concept_id as integer) as drug_concept_id,
    cast(ingredient_concept_id as integer) as ingredient_concept_id,
    amount_value,
    cast(amount_unit_concept_id as integer) as amount_unit_concept_id,
    numerator_value,
    cast(numerator_unit_concept_id as integer) as numerator_unit_concept_id,
    denominator_value,
    cast(denominator_unit_concept_id as integer) as denominator_unit_concept_id,
    box_size,
    try_cast(
        strptime(cast(valid_start_date as varchar), '%Y%m%d') as date
    ) as valid_start_date,
    try_cast(
        strptime(cast(valid_end_date as varchar), '%Y%m%d') as date
    ) as valid_end_date,
    invalid_reason
from {{ source("athena_vocabulary", "DRUG_STRENGTH") }}
