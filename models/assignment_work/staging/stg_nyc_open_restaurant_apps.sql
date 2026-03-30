WITH source AS (

    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}

),

cleaned AS (

    SELECT

        -- remove raw columns we will redefine
        * EXCEPT (
            objectid,
            time_of_submission,
            borough,
            zip
        ),

        -- primary key
        CAST(objectid AS STRING) AS application_id,

        -- timestamp
        CAST(time_of_submission AS TIMESTAMP) AS submission_timestamp,

        -- borough standardization (light cleaning only)
        TRIM(CAST(borough AS STRING)) AS borough,

        -- ZIP cleaning (as professor hinted)
        CASE 
            WHEN zip IS NULL THEN NULL
            WHEN LENGTH(TRIM(zip)) = 5 THEN TRIM(zip)
            ELSE NULL
        END AS zip_code,

        -- optional light casting (not overdoing)
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- keep rest mostly as-is (small dataset → less cleaning)
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE
        objectid IS NOT NULL
        AND time_of_submission IS NOT NULL

),

deduplicated AS (

    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY application_id
        ORDER BY submission_timestamp DESC
    ) = 1

)

SELECT * FROM deduplicated;