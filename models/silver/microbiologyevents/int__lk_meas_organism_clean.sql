SELECT DISTINCT
    src.subject_id AS subject_id,
    src.microevent_id as microevent_id,
    src.hadm_id AS hadm_id,
    cr.order_provider_id AS provider_id,
    cr.start_datetime AS start_datetime,
    cr.end_datetime AS end_datetime,
    src.spec_itemid AS spec_itemid, -- d_micro.itemid, type of specimen taken
    src.test_itemid AS test_itemid, -- d_micro.itemid, test taken from the specimen
    src.org_itemid AS org_itemid, -- d_micro.itemid, organism which has grown
    cr.trace_id_spec AS trace_id_spec, -- to link org and spec in fact_relationship
    --
    'micro.organism' AS unit_id,
    src.load_table_id AS load_table_id,
    CAST(hash(
        src.load_row_id,
        cr.order_provider_id,
        'micro.organism'
    ) >> 1 AS BIGINT) AS load_row_id,
    cr.trace_id_org AS trace_id -- trace_id for test-organism
FROM
    {{ ref("stg__microbiologyevents") }} AS src
INNER JOIN
    {{ ref("int__lk_micro_cross_ref") }} AS cr
        ON src.trace_id = cr.trace_id_org