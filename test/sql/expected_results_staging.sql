CREATE OR REPLACE TABLE dv_stg.orders_20190806_000000
  (h_customer_hashkey TEXT (32) NOT NULL, r_timestamp TIMESTAMP_NTZ NOT NULL, r_source TEXT NOT NULL, customer_id TEXT NOT NULL, h_order_hashkey TEXT (32) NOT NULL, order_id TEXT NOT NULL, l_order_customer_hashkey TEXT (32) NOT NULL, ck_test_string TEXT NOT NULL, ck_test_timestamp TIMESTAMP_NTZ NOT NULL, hs_customer_hashdiff TEXT (32) NOT NULL, test_string TEXT , test_date DATE , test_timestamp TIMESTAMP_NTZ , test_integer NUMBER (38, 0) , test_decimal NUMBER (18, 8) , x_customer_id TEXT , grouping_key TEXT , ls_order_customer_eff_hashdiff TEXT (32) NOT NULL, dummy_descriptive_field TEXT NOT NULL) AS
  SELECT MD5(COALESCE(customer_id, 'dv_unknown')) AS h_customer_hashkey, CAST('2019-08-06T00:00:00.000000Z' AS TIMESTAMP) AS r_timestamp, 'test' AS r_source, COALESCE(customer_id, 'dv_unknown') AS customer_id, MD5(COALESCE(order_id, 'dv_unknown')) AS h_order_hashkey, COALESCE(order_id, 'dv_unknown') AS order_id, MD5(COALESCE(order_id, 'dv_unknown')||'|~~|'||COALESCE(customer_id, 'dv_unknown')||'|~~|'||COALESCE(CAST(ck_test_string AS VARCHAR), '')||'|~~|'||COALESCE(CAST(ck_test_timestamp AS VARCHAR), '')) AS l_order_customer_hashkey, ck_test_string, ck_test_timestamp, MD5(REGEXP_REPLACE(COALESCE(customer_id, 'dv_unknown')||'|~~|'||COALESCE(CAST(test_string AS VARCHAR), '')||'|~~|'||COALESCE(CAST(test_date AS VARCHAR), '')||'|~~|'||COALESCE(CAST(test_timestamp AS VARCHAR), '')||'|~~|'||COALESCE(CAST(test_integer AS VARCHAR), '')||'|~~|'||COALESCE(CAST(test_decimal AS VARCHAR), '')||'|~~|'||COALESCE(CAST(x_customer_id AS VARCHAR), '')||'|~~|'||COALESCE(CAST(grouping_key AS VARCHAR), ''), '(\\|~~\\|)+$', '')) AS hs_customer_hashdiff, test_string, test_date, test_timestamp, test_integer, test_decimal, x_customer_id, grouping_key, MD5(REGEXP_REPLACE(COALESCE(order_id, 'dv_unknown')||'|~~|'||COALESCE(customer_id, 'dv_unknown')||'|~~|'||COALESCE(CAST(ck_test_string AS VARCHAR), '')||'|~~|'||COALESCE(CAST(ck_test_timestamp AS VARCHAR), '')||'|~~|'||COALESCE(CAST(dummy_descriptive_field AS VARCHAR), ''), '(\\|~~\\|)+$', '')) AS ls_order_customer_eff_hashdiff, dummy_descriptive_field
  FROM dv_extract.extract_orders;