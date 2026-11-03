WITH d_micro AS (
    SELECT DISTINCT
        ab_itemid                   AS itemid,
        ab_name                     AS label,
        'ANTIBIOTIC'                AS category,
        json_object('field_name', 'ab_itemid', 'itemid', ab_itemid)::text AS trace_id
    FROM
        {{ ref("stg__microbiologyevents") }}
    WHERE
        ab_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        test_itemid                 AS itemid,
        test_name                   AS label,
        'MICROTEST'                 AS category,
        json_object('field_name', 'test_itemid', 'itemid', test_itemid)::text AS trace_id
    FROM
        {{ ref("stg__microbiologyevents") }}
    WHERE
        test_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        org_itemid                  AS itemid,
        org_name                    AS label,
        'ORGANISM'                  AS category,
        json_object('field_name', 'org_itemid', 'itemid', org_itemid)::text AS trace_id
    FROM
        {{ ref("stg__microbiologyevents") }}
    WHERE
        org_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        spec_itemid                 AS itemid,
        spec_type_desc              AS label,
        'SPECIMEN'                  AS category,
        json_object('field_name', 'spec_itemid', 'itemid', spec_itemid)::text AS trace_id
    FROM
        {{ ref("stg__microbiologyevents") }}
    WHERE
        spec_itemid IS NOT NULL
)
SELECT
    itemid                      AS itemid,
    label                       AS label,
    category                    AS category,
    'microbiologyevents'        AS load_table_id,
    CAST(hash(itemid) >> 1 AS BIGINT) AS load_row_id,
    trace_id                    AS trace_id
FROM
    d_micro