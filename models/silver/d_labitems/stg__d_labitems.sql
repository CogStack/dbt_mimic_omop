SELECT
    itemid                              AS itemid,
    label                               AS label,
    fluid                               AS fluid,
    category                            AS category,
    CAST(NULL AS TEXT)                  AS loinc_code,
    'd_labitems'                        AS load_table_id,
    CAST(hash(itemid) >> 1 AS BIGINT) AS load_row_id,
    json_object('itemid', itemid)::text AS trace_id
FROM
    {{ source("mimic", "d_labitems") }} AS dlab