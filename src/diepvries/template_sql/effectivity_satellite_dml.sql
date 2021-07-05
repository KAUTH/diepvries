MERGE INTO {target_schema}.{data_vault_table} AS satellite
  USING (
    WITH
      filtered_staging AS (
        SELECT * FROM (
            SELECT
              staging.*,
              ROW_NUMBER() OVER (PARTITION BY {staging_driving_keys} ORDER BY {record_source}, {staging_hashdiff_field}) = 1 AS _rank
            FROM {staging_schema}.{staging_table} AS staging
              CROSS JOIN (
                           SELECT
                             MAX({record_start_timestamp}) AS max_r_timestamp
                           FROM {target_schema}.{data_vault_table}
                         ) AS max_satellite_timestamp
            WHERE staging.{record_start_timestamp} >=
                  COALESCE(max_satellite_timestamp.max_r_timestamp, '1970-01-01 00:00:00')
        )
        WHERE _rank=1
      ),
      effectivity_satellite AS (
        SELECT
          {link_driving_keys},
          satellite.*
        FROM filtered_staging AS staging
          INNER JOIN {target_schema}.{link_table} AS l
                     ON ({link_driving_key_condition})
          INNER JOIN {target_schema}.{data_vault_table} AS satellite
                     ON (l.{hashkey_field} = satellite.{hashkey_field}
                         AND satellite.{record_end_timestamp_name} = {end_of_time})
      ),
      staging_satellite_affected_records AS (
        /* Records that will be inserted (don't exist in target table or exist
          in the target table but the hashdiff changed). As the r_timestamp is fetched
          from the staging table, these records will always be included in the
          WHEN NOT MATCHED condition of the MERGE command. */
        SELECT
          {staging_driving_keys},
          staging.{hashkey_field},
          staging.{staging_hashdiff_field},
          staging.{record_start_timestamp},
          staging.{record_source}
          {staging_descriptive_fields}
        FROM filtered_staging AS staging
          LEFT JOIN effectivity_satellite AS satellite
                    ON ({satellite_driving_key_condition})
        WHERE satellite.{hashkey_field} IS NULL
           OR satellite.{hashdiff_field} <> staging.{staging_hashdiff_field}
        UNION ALL
        /* Records from the target table that will have its r_timestamp_end updated
          (hashkey already exists in target table, but hashdiff changed). As the
          r_timestamp is fetched from the target table, these records will always be
          included in the WHEN MATCHED condition of the MERGE command. */
        SELECT
          {satellite_driving_keys},
          satellite.{hashkey_field},
          satellite.{hashdiff_field} AS {staging_hashdiff_field},
          satellite.{record_start_timestamp},
          satellite.{record_source}
          {satellite_descriptive_fields}
        FROM filtered_staging AS staging
          INNER JOIN effectivity_satellite AS satellite
                     ON ({satellite_driving_key_condition})
        WHERE satellite.{hashdiff_field} <> staging.{staging_hashdiff_field}
      )
    SELECT
      {hashkey_field},
      {staging_hashdiff_field},
      {record_start_timestamp} AS {record_start_timestamp},
      {record_end_timestamp_expression},
      {record_source}
      {descriptive_fields}
    FROM staging_satellite_affected_records
  ) AS staging
  ON (satellite.{hashkey_field} = staging.{hashkey_field}
      AND satellite.{record_start_timestamp} = staging.{record_start_timestamp})
  WHEN MATCHED THEN
    UPDATE SET satellite.{record_end_timestamp_name} = staging.{record_end_timestamp_name}
  WHEN NOT MATCHED
    THEN
    INSERT ({fields})
      VALUES (
               staging.{hashkey_field},
               staging.{staging_hashdiff_field},
               staging.{record_start_timestamp},
               staging.{record_end_timestamp_name},
               staging.{record_source}
               {staging_descriptive_fields});