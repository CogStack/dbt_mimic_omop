-- not shipped by Athena; part of the CDM vocabulary tables, empty unless a site adds mappings
select
    cast(null as varchar) as source_code,
    cast(null as integer) as source_concept_id,
    cast(null as varchar) as source_vocabulary_id,
    cast(null as varchar) as source_code_description,
    cast(null as integer) as target_concept_id,
    cast(null as varchar) as target_vocabulary_id,
    cast(null as date) as valid_start_date,
    cast(null as date) as valid_end_date,
    cast(null as varchar) as invalid_reason
limit 0
