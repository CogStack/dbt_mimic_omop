with tmp_target_condition AS (
SELECT
    co.condition_occurrence_id AS condition_occurrence_id,
    co.person_id AS person_id,
    co.condition_concept_id AS condition_concept_id,
    co.condition_start_date AS condition_start_date,
    COALESCE(
        co.condition_end_date,
        co.condition_start_date + INTERVAL '1 day'
    ) AS condition_end_date
FROM
    {{ ref("condition_occurrence") }} AS co
WHERE
    co.condition_concept_id != 0
),

tmp_dates_un_condition AS (
SELECT
    person_id AS person_id,
    condition_concept_id AS condition_concept_id,
    condition_start_date AS event_date,
    -1 AS event_type,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, condition_concept_id
        ORDER BY condition_start_date
    ) AS start_ordinal
FROM
    tmp_target_condition
UNION ALL
SELECT
    person_id AS person_id,
    condition_concept_id AS condition_concept_id,
    condition_end_date + INTERVAL '30 day' AS event_date,
    1 AS event_type,
    NULL AS start_ordinal
FROM
    tmp_target_condition
),

tmp_dates_rows_condition AS (
SELECT
    person_id AS person_id,
    condition_concept_id AS condition_concept_id,
    event_date AS event_date,
    event_type AS event_type,
    MAX(start_ordinal) OVER (
        PARTITION BY person_id, condition_concept_id
        ORDER BY event_date, event_type
        ROWS UNBOUNDED PRECEDING
    ) AS start_ordinal,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, condition_concept_id
        ORDER BY event_date, event_type
    ) AS overall_ord
FROM
    tmp_dates_un_condition
),

tmp_enddates_condition AS (
SELECT
    person_id AS person_id,
    condition_concept_id AS condition_concept_id,
    event_date - INTERVAL '30 day' AS end_date -- unpad the end date
FROM
    tmp_dates_rows_condition AS e
WHERE
    (2 * e.start_ordinal) - e.overall_ord = 0
),

tmp_conditionends AS (
SELECT
    c.person_id AS person_id,
    c.condition_concept_id AS condition_concept_id,
    c.condition_start_date AS condition_start_date,
    MIN(e.end_date) AS era_end_date
FROM
    tmp_target_condition AS c
JOIN
    tmp_enddates_condition AS e
    ON c.person_id = e.person_id
    AND c.condition_concept_id = e.condition_concept_id
    AND e.end_date >= c.condition_start_date
GROUP BY
    c.condition_occurrence_id,
    c.person_id,
    c.condition_concept_id,
    c.condition_start_date
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(person_id, condition_concept_id, era_end_date)) AS INTEGER) AS condition_era_id,
    person_id AS person_id,
    condition_concept_id AS condition_concept_id,
    MIN(condition_start_date) AS condition_era_start_date,
    CAST(era_end_date AS DATE) AS condition_era_end_date,
    COUNT(*) AS condition_occurrence_count
FROM
    tmp_conditionends
GROUP BY
    person_id,
    condition_concept_id,
    era_end_date
ORDER BY
    person_id,
    condition_concept_id
