select
    subject_id::integer             AS subject_id,
    anchor_year::integer            AS anchor_year,
    anchor_age::integer             AS anchor_age,
    anchor_year_group               AS anchor_year_group,
    gender                          AS gender,
    dod::date                       AS dod,
    'patients'                      AS load_table_id,
    CAST(hash(subject_id) >> 1 AS BIGINT)                AS load_row_id,
    json_object(
        'subject_id', subject_id
    )::text                         AS trace_id
from {{ source("mimic", "patients") }}
