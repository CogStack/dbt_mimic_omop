SELECT
    src.* REPLACE (ids.measurement_id AS measurement_id)
FROM
    {{ ref('int__measurement') }} AS src
INNER JOIN
    {{ ref('int__measurement_id_map') }} AS ids
        ON ids.hash_id = src.measurement_id
