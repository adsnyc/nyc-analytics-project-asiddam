{{ config(
    schema='nyc_transit_restaurants_staging'
) }}

-- Clean and standardize restaurant application data
-- One row per application

WITH cleaned AS (

    SELECT

        -- keep everything except columns we will redefine
        * EXCEPT (
            objectid,
            time_of_submission,
            borough,
            zip,
            latitude,
            longitude
        ),

        -- primary key
        CAST(objectid AS STRING) AS application_id,

        -- timestamp
        CAST(time_of_submission AS TIMESTAMP) AS submission_timestamp,

        -- borough cleaning (same style as Part 4)
        TRIM(CAST(borough AS STRING)) AS borough,

        -- zip cleaning (simple like professor expectation)
        CASE
            WHEN zip IS NULL THEN NULL
            WHEN LENGTH(TRIM(zip)) = 5 THEN TRIM(zip)
            ELSE NULL
        END AS zip_code,

        -- light casting
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}

    WHERE objectid IS NOT NULL
    AND time_of_submission IS NOT NULL

)

SELECT * FROM cleaned