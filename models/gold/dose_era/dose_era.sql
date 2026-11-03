with tmp_drugIngredientExp AS (
SELECT
    de.drug_exposure_id AS drug_exposure_id,
    de.person_id AS person_id,
    de.drug_exposure_start_date AS drug_exposure_start_date,
    de.drug_exposure_end_date AS drug_exposure_end_date,
    de.drug_concept_id AS drug_concept_id,
    ds.ingredient_concept_id AS ingredient_concept_id,
    de.refills AS refills,
    CASE
        WHEN de.days_supply = 0 THEN 1
        ELSE de.days_supply
    END AS days_supply,
    de.quantity AS quantity,
    ds.box_size AS box_size,
    ds.amount_value AS amount_value,
    ds.amount_unit_concept_id AS amount_unit_concept_id,
    ds.numerator_value AS numerator_value,
    ds.numerator_unit_concept_id AS numerator_unit_concept_id,
    ds.denominator_value AS denominator_value,
    ds.denominator_unit_concept_id AS denominator_unit_concept_id,
    c.concept_class_id AS concept_class_id
FROM {{ ref('drug_exposure') }} AS de
INNER JOIN {{ ref('drug_strength') }} AS ds
    ON de.drug_concept_id = ds.drug_concept_id
INNER JOIN {{ ref('concept_ancestor') }} AS ca
    ON de.drug_concept_id = ca.descendant_concept_id
    AND ds.ingredient_concept_id = ca.ancestor_concept_id
LEFT JOIN {{ ref('stg__voc_concept') }} AS c
    ON de.drug_concept_id = c.concept_id
    AND c.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
),

tmp_drugWithDose AS (
SELECT
    drug_exposure_id AS drug_exposure_id,
    person_id AS person_id,
    drug_exposure_start_date AS drug_exposure_start_date,
    drug_exposure_end_date AS drug_exposure_end_date,
    ingredient_concept_id AS drug_concept_id,
    refills AS refills,
    days_supply AS days_supply,
    quantity AS quantity,
    -- CASE 1
    CASE
        WHEN amount_value IS NOT NULL
            AND denominator_unit_concept_id IS NULL
        THEN
            CASE
                WHEN quantity > 0
                    AND box_size IS NOT NULL
                    AND concept_class_id IN ('Branded Drug Box', 'Clinical Drug Box', 'Marketed Product',
                                             'Quant Branded Box', 'Quant Clinical Box')
                THEN amount_value * quantity * box_size / days_supply
                WHEN quantity > 0
                    AND concept_class_id NOT IN ('Branded Drug Box', 'Clinical Drug Box', 'Marketed Product',
                                                 'Quant Branded Box', 'Quant Clinical Box')
                THEN amount_value * quantity / days_supply
                WHEN quantity = 0 AND box_size IS NOT NULL
                THEN amount_value * box_size / days_supply
                WHEN quantity = 0 AND box_size IS NULL
                THEN -1
            END
        -- CASE 2, 3
        WHEN numerator_value IS NOT NULL
            AND concept_class_id != 'Ingredient'
            AND denominator_unit_concept_id != 8505     --hour
        THEN
            CASE
                WHEN denominator_value IS NOT NULL
                THEN numerator_value / days_supply
                WHEN denominator_value IS NULL AND quantity != 0
                THEN numerator_value * quantity / days_supply
                WHEN denominator_value IS NULL AND quantity = 0
                THEN -1
            END
        -- CASE 4
        WHEN numerator_value IS NOT NULL
            AND concept_class_id = 'Ingredient'
            AND denominator_unit_concept_id != 8505
        THEN
            CASE
                WHEN quantity > 0
                THEN quantity / days_supply
                WHEN quantity = 0
                THEN -1
            END
        -- CASE 6
        WHEN numerator_value IS NOT NULL
            AND denominator_unit_concept_id = 8505
        THEN
            CASE
                WHEN denominator_value IS NOT NULL
                THEN numerator_value * 24 / denominator_value
                WHEN denominator_value IS NULL AND quantity != 0
                THEN numerator_value * 24 / quantity
                WHEN denominator_value IS NULL AND quantity = 0
                THEN -1
            END
    END AS dose_value,
    -- CASE 1
    CASE
        WHEN amount_value IS NOT NULL
            AND denominator_unit_concept_id IS NULL
        THEN
            CASE
                WHEN quantity = 0 AND box_size IS NULL
                THEN -1
                ELSE amount_unit_concept_id
            END
        -- CASE 2, 3
        WHEN numerator_value IS NOT NULL
            AND concept_class_id != 'Ingredient'
            AND denominator_unit_concept_id != 8505     -- hour
        THEN
            CASE
                WHEN denominator_value IS NULL AND quantity = 0
                THEN -1
                ELSE numerator_unit_concept_id
            END
        -- CASE 4
        WHEN numerator_value IS NOT NULL
            AND concept_class_id = 'Ingredient'
            AND denominator_unit_concept_id != 8505
        THEN
            CASE
                WHEN quantity > 0
                THEN 0
                WHEN quantity = 0
                THEN -1
            END
        -- CASE 6
        WHEN numerator_value IS NOT NULL
            AND denominator_unit_concept_id = 8505
        THEN
            CASE
                WHEN denominator_value IS NULL AND quantity = 0
                THEN -1
                ELSE numerator_unit_concept_id
            END
    END AS unit_concept_id
FROM tmp_drugIngredientExp
),

tmp_cteDoseTarget AS (
SELECT
    dwd.drug_exposure_id AS drug_exposure_id,
    dwd.person_id AS person_id,
    dwd.drug_concept_id AS drug_concept_id,
    dwd.unit_concept_id AS unit_concept_id,
    dwd.dose_value AS dose_value,
    dwd.drug_exposure_start_date AS drug_exposure_start_date,
    dwd.days_supply AS days_supply,
    COALESCE(dwd.drug_exposure_end_date,
        NULLIF(
            drug_exposure_start_date + INTERVAL '1 day' * (1 * days_supply * (COALESCE(refills, 0) + 1)),
            drug_exposure_start_date
        ),
        dwd.drug_exposure_start_date + INTERVAL '1 day'
    ) AS drug_exposure_end_date
FROM tmp_drugWithDose AS dwd
WHERE 
    dose_value <> -1
),

tmp_cteDoseEndDates_rawdata AS (
SELECT
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    unit_concept_id AS unit_concept_id,
    dose_value AS dose_value,
    drug_exposure_start_date AS event_date,
    -1 AS event_type,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS INTEGER)
        ORDER BY drug_exposure_start_date, dose_value
    ) AS start_ordinal
FROM tmp_cteDoseTarget

UNION ALL

SELECT
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    unit_concept_id AS unit_concept_id,
    dose_value AS dose_value,
    drug_exposure_end_date + INTERVAL '30 day' AS event_date,
    1 AS event_type,
    NULL AS start_ordinal
FROM tmp_cteDoseTarget
),

tmp_cteDoseEndDates_e AS (
SELECT
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    unit_concept_id AS unit_concept_id,
    dose_value AS dose_value,
    event_date AS event_date,
    event_type AS event_type,
    MAX(start_ordinal) OVER (
        PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS INTEGER) -- double-check if it is a valid cast
        ORDER BY event_date, event_type, dose_value
        ROWS UNBOUNDED PRECEDING
    ) AS start_ordinal,
    ROW_NUMBER() OVER (
        PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS INTEGER)
        ORDER BY event_date, event_type, dose_value
    ) AS overall_ord
FROM tmp_cteDoseEndDates_rawdata
),

tmp_cteDoseEndDates AS (
SELECT
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    unit_concept_id AS unit_concept_id,
    dose_value AS dose_value,
    event_date - INTERVAL '30 day' AS end_date -- unpad the end date
FROM tmp_cteDoseEndDates_e
WHERE
    (2 * start_ordinal) - overall_ord = 0
),

tmp_cteDoseFinalEnds AS (
SELECT
    dt.person_id AS person_id,
    dt.drug_concept_id AS drug_concept_id,
    dt.unit_concept_id AS unit_concept_id,
    dt.dose_value AS dose_value,
    dt.drug_exposure_start_date AS drug_exposure_start_date,
    MIN(e.end_date) AS drug_era_end_date
FROM tmp_cteDoseTarget AS dt
INNER JOIN tmp_cteDoseEndDates AS e
    ON dt.person_id = e.person_id
    AND dt.drug_concept_id = e.drug_concept_id
    AND dt.unit_concept_id = e.unit_concept_id
    AND dt.dose_value = e.dose_value
    AND e.end_date >= dt.drug_exposure_start_date
GROUP BY
    dt.drug_exposure_id,
    dt.person_id,
    dt.drug_concept_id,
    dt.drug_exposure_start_date,
    dt.unit_concept_id,
    dt.dose_value
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY hash(
        person_id, 
        drug_concept_id, 
        unit_concept_id, 
        dose_value, 
        drug_era_end_date)) AS INTEGER) AS dose_era_id,
    person_id AS person_id,
    drug_concept_id AS drug_concept_id,
    unit_concept_id AS unit_concept_id,
    dose_value AS dose_value,
    MIN(drug_exposure_start_date) AS dose_era_start_date,
    CAST(drug_era_end_date AS DATE) AS dose_era_end_date
FROM tmp_cteDoseFinalEnds
GROUP BY
    person_id,
    drug_concept_id,
    unit_concept_id,
    dose_value,
    drug_era_end_date
ORDER BY
    person_id,
    drug_concept_id