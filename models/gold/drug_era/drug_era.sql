with lk_join_voc_drug AS (
SELECT DISTINCT
    ca.descendant_concept_id AS descendant_concept_id,
    ca.ancestor_concept_id AS ancestor_concept_id,
    c.concept_id AS concept_id
FROM
    {{ source("athena_vocabulary", "CONCEPT_ANCESTOR") }} AS ca
JOIN
    {{ ref("stg__voc_concept") }} AS c
    ON ca.ancestor_concept_id = c.concept_id
    AND c.vocabulary_id IN ('RxNorm', 'RxNorm Extension')   -- selects RxNorm, RxNorm Extension vocabulary_id
    AND c.concept_class_id = 'Ingredient'                   -- selects the Ingredients only.
                                                            -- There are other concept_classes in RxNorm that
                                                                -- we are not interested in.
),

tmp_pretarget_drug AS (
SELECT
    d.drug_exposure_id AS drug_exposure_id,
    d.person_id AS person_id,
    v.concept_id AS ingredient_concept_id,
    d.drug_exposure_start_date AS drug_exposure_start_date,
    d.days_supply AS days_supply,
    d.drug_exposure_end_date AS drug_exposure_end_date
FROM
    {{ ref("drug_exposure") }} AS d
JOIN
    lk_join_voc_drug AS v
    ON v.descendant_concept_id = d.drug_concept_id
WHERE
    d.drug_concept_id != 0
),

tmp_subenddates_un_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    drug_exposure_start_date AS event_date,
    -1 AS event_type,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY drug_exposure_start_date
    ) AS start_ordinal
FROM
    tmp_pretarget_drug
UNION ALL
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    drug_exposure_end_date AS event_date,
    1 AS event_type,
    NULL AS start_ordinal
FROM
    tmp_pretarget_drug
),



tmp_subenddates_rows_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    event_date AS event_date,
    event_type AS event_type,
    MAX(start_ordinal) OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY event_date, event_type
        ROWS UNBOUNDED PRECEDING
    ) AS start_ordinal,
            -- this pulls the current START down from the prior rows so that the NULLs
            -- from the END DATES will contain a value we can compare with
    ROW_NUMBER() OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY event_date, event_type
    ) AS overall_ord
            -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
FROM
    tmp_subenddates_un_drug
),

tmp_subenddates_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    event_date AS end_date
FROM
    tmp_subenddates_rows_drug AS e
WHERE
    (2 * e.start_ordinal) - e.overall_ord = 0
),

temp_ends_drug AS (
SELECT
    dt.person_id AS person_id,
    dt.ingredient_concept_id AS drug_concept_id,
    dt.drug_exposure_start_date AS drug_exposure_start_date,
    MIN(e.end_date) AS drug_sub_exposure_end_date
FROM
    tmp_pretarget_drug AS dt
JOIN
    tmp_subenddates_drug AS e
        ON dt.person_id = e.person_id
        AND dt.ingredient_concept_id = e.ingredient_concept_id
        AND e.end_date >= dt.drug_exposure_start_date
GROUP BY
    dt.drug_exposure_id,
    dt.person_id,
    dt.ingredient_concept_id,
    dt.drug_exposure_start_date
),

tmp_sub_drug AS (
SELECT
    ROW_NUMBER() OVER (
        PARTITION BY person_id, drug_concept_id, drug_sub_exposure_end_date
        ORDER BY person_id, drug_concept_id
    ) AS row_number,
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    MIN(drug_exposure_start_date) AS drug_sub_exposure_start_date,
    drug_sub_exposure_end_date AS drug_sub_exposure_end_date,
    COUNT(*) AS drug_exposure_count
FROM
    temp_ends_drug
GROUP BY
    person_id,
    drug_concept_id,
    drug_sub_exposure_end_date
ORDER BY
    person_id,
    drug_concept_id
),

tmp_finaltarget_drug AS (
SELECT
    row_number AS row_number,
    person_id AS person_id,
    drug_concept_id AS ingredient_concept_id,
    drug_sub_exposure_start_date AS drug_sub_exposure_start_date,
    drug_sub_exposure_end_date AS drug_sub_exposure_end_date,
    drug_exposure_count AS drug_exposure_count,
    (drug_sub_exposure_end_date - drug_sub_exposure_start_date) AS days_exposed
FROM
    tmp_sub_drug
),

tmp_enddates_un_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    drug_sub_exposure_start_date AS event_date,
    -1 AS event_type,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY drug_sub_exposure_start_date
    ) AS start_ordinal
FROM
    tmp_finaltarget_drug

UNION ALL

SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    drug_sub_exposure_end_date + INTERVAL '30 day' AS event_date,
    1 AS event_type,
    NULL AS start_ordinal
FROM
    tmp_finaltarget_drug
),

tmp_enddates_rows_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    event_date AS event_date,
    event_type AS event_type,
    MAX(start_ordinal) OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY event_date, event_type
        ROWS UNBOUNDED PRECEDING
    ) AS start_ordinal,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, ingredient_concept_id
        ORDER BY event_date, event_type
    ) AS overall_ord
FROM
    tmp_enddates_un_drug
),

tmp_enddates_drug AS (
SELECT
    person_id AS person_id,
    ingredient_concept_id AS ingredient_concept_id,
    event_date - INTERVAL '30 day' AS end_date
FROM
    tmp_enddates_rows_drug AS e
WHERE
    (2 * e.start_ordinal) - e.overall_ord = 0
),

tmp_drugera_ends_drug AS (
SELECT
    ft.person_id AS person_id,
    ft.ingredient_concept_id AS ingredient_concept_id,
    ft.drug_sub_exposure_start_date AS drug_sub_exposure_start_date,
    MIN(e.end_date) AS drug_era_end_date,
    ft.drug_exposure_count AS drug_exposure_count,
    ft.days_exposed AS days_exposed
FROM
    tmp_finaltarget_drug AS ft
JOIN
    tmp_enddates_drug AS e
        ON ft.person_id = e.person_id
        AND e.end_date >= ft.drug_sub_exposure_start_date
        AND ft.ingredient_concept_id = e.ingredient_concept_id
GROUP BY
    ft.person_id,
    ft.ingredient_concept_id,
    ft.drug_sub_exposure_start_date,
    ft.drug_exposure_count,
    ft.days_exposed
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(
        person_id,
        ingredient_concept_id,
        MIN(drug_sub_exposure_start_date),
        drug_era_end_date
    )) AS INTEGER) AS drug_era_id,
    person_id AS person_id,
    ingredient_concept_id AS drug_concept_id,
    MIN(drug_sub_exposure_start_date) AS drug_era_start_date,
    CAST(drug_era_end_date AS DATE) AS drug_era_end_date,
    CAST(SUM(drug_exposure_count) AS BIGINT) AS drug_exposure_count,
    CAST(EXTRACT(DAY FROM (drug_era_end_date - MIN(drug_sub_exposure_start_date))) 
        - SUM(days_exposed) AS BIGINT) AS gap_days
FROM
    tmp_drugera_ends_drug
GROUP BY
    person_id,
    drug_era_end_date,
    ingredient_concept_id
ORDER BY
    person_id,
    ingredient_concept_id