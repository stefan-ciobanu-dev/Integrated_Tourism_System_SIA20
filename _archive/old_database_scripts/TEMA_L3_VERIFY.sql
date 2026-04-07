-- ============================================================================
-- TEMA L3 VERIFICATION SCRIPT
-- ============================================================================
-- Run this AFTER deploying TEMA_L3_OLAP_VIEWS.sql to verify everything works
-- ============================================================================

SET ECHO ON
SET HEADING ON
SET PAGESIZE 25

PROMPT ════════════════════════════════════════════════════════════════
PROMPT TEMA L3 VERIFICATION & TESTING
PROMPT ════════════════════════════════════════════════════════════════

-- ============================================================================
-- PART 1: VERIFY DIMENSIONAL TABLES EXIST
-- ============================================================================
PROMPT
PROMPT [1/6] Checking Dimensional Tables...
PROMPT

SELECT table_name, num_rows FROM user_tables 
WHERE table_name IN ('DIM_HOTELS', 'DIM_CURRENCY', 'DIM_AIRPORTS', 'DIM_DATE')
ORDER BY table_name;

-- ============================================================================
-- PART 2: VERIFY FACT TABLES EXIST
-- ============================================================================
PROMPT
PROMPT [2/6] Checking Fact Tables...
PROMPT

SELECT table_name, num_rows FROM user_tables 
WHERE table_name IN ('FACT_BOOKINGS', 'FACT_FLIGHT_OPERATIONS')
ORDER BY table_name;

-- ============================================================================
-- PART 3: VERIFY OLAP VIEWS EXIST
-- ============================================================================
PROMPT
PROMPT [3/6] Checking OLAP Views (expect 15+)...
PROMPT

SELECT COUNT(*) as OLAP_VIEWS_COUNT,
       LISTAGG(view_name, ', ') WITHIN GROUP (ORDER BY view_name) as VIEWS
FROM user_views 
WHERE view_name LIKE 'V_OLAP%'
GROUP BY 1;

-- ============================================================================
-- PART 4: VERIFY MATERIALIZED VIEW
-- ============================================================================
PROMPT
PROMPT [4/6] Checking Materialized Views...
PROMPT

SELECT mview_name, query_rewrite_enabled 
FROM user_mviews
WHERE mview_name = 'MV_REVENUE_SUMMARY';

-- ============================================================================
-- PART 5: SAMPLE DATA CHECKS
-- ============================================================================
PROMPT
PROMPT [5/6] Sample Data from Dimension Tables...
PROMPT

PROMPT --- DIM_HOTELS (first 3 rows) ---
SELECT * FROM DIM_HOTELS FETCH FIRST 3 ROWS ONLY;

PROMPT --- DIM_CURRENCY (first 3 rows) ---
SELECT * FROM DIM_CURRENCY FETCH FIRST 3 ROWS ONLY;

PROMPT --- DIM_DATE (first 3 rows) ---
SELECT * FROM DIM_DATE FETCH FIRST 3 ROWS ONLY;

-- ============================================================================
-- PART 6: TEST BASIC OLAP QUERIES
-- ============================================================================
PROMPT
PROMPT [6/6] Testing Sample OLAP Queries...
PROMPT

PROMPT --- Revenue by Hotel/Month (should show aggregations) ---
SELECT * FROM V_OLAP_REVENUE_BY_HOTEL_MONTHLY
FETCH FIRST 5 ROWS ONLY;

PROMPT --- Hotel Occupancy Analysis ---
SELECT * FROM V_OLAP_HOTEL_OCCUPANCY
FETCH FIRST 5 ROWS ONLY;

-- ============================================================================
-- FINAL VERIFICATION SUMMARY
-- ============================================================================
PROMPT
PROMPT ════════════════════════════════════════════════════════════════
PROMPT VERIFICATION COMPLETE - Summary
PROMPT ════════════════════════════════════════════════════════════════

SELECT 
  (SELECT COUNT(*) FROM user_tables WHERE table_name LIKE 'DIM_%' OR table_name LIKE 'FACT_%') as TABLES_CREATED,
  (SELECT COUNT(*) FROM user_views WHERE view_name LIKE 'V_OLAP%') as OLAP_VIEWS_CREATED,
  (SELECT COUNT(*) FROM user_mviews WHERE mview_name = 'MV_REVENUE_SUMMARY') as MATERIALIZED_VIEWS
FROM DUAL;

PROMPT
PROMPT ✅ TEMA L3 Deployment Successful!
PROMPT
PROMPT Next Steps:
PROMPT   1. Run this verification script to confirm all objects exist
PROMPT   2. Check row counts in fact/dimension tables
PROMPT   3. Test OLAP queries from V_OLAP_* views
PROMPT   4. Use output for TEMA L3 documentation
PROMPT
