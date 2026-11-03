-- 32-bit measurement_id for each 64-bit hash id, numbered in hash order so reruns give the same ids;
-- also used by fact_relationship, which links microbiology measurements by their hash ids
SELECT
    measurement_id AS hash_id,
    CAST(ROW_NUMBER() OVER (ORDER BY measurement_id) AS INTEGER) AS measurement_id
FROM
    {{ ref('int__measurement') }}
