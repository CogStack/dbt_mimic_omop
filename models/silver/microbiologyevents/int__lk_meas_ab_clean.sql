SELECT
    src.subject_id AS subject_id,
    src.microevent_id as microevent_id,
    src.hadm_id AS hadm_id,
    cr.order_provider_id AS provider_id,
    cr.start_datetime AS start_datetime,
    src.ab_itemid AS ab_itemid, -- antibiotic tested
    src.dilution_comparison AS dilution_comparison, -- operator sign
    src.dilution_value AS dilution_value, -- numeric dilution value
    src.interpretation AS interpretation, -- degree of resistance
    cr.trace_id_org AS trace_id_org, -- to link org to ab in fact_relationship
    --
    'micro.antibiotics' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(
        src.load_row_id,
        cr.order_provider_id,
        'micro.antibiotics'
    ) >> 1 AS BIGINT) AS load_row_id,
    src.trace_id AS trace_id -- trace_id for antibiotics, no grouping is needed
FROM
    {{ ref("stg__microbiologyevents") }} AS src
INNER JOIN
    {{ ref("int__lk_micro_cross_ref") }} AS cr
        ON src.trace_id = cr.trace_id_ab
WHERE
    src.ab_itemid IS NOT NULL