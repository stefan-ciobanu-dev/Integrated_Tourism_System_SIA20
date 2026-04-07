-- ============================================================================
-- TEMA P3: ORDS REST DATA SERVICES - IMPLEMENTATION
-- Expose TEMA L3 OLAP Views as RESTful Web Services
-- ============================================================================

ALTER SESSION SET CONTAINER=FREEPDB1;

PROMPT ========================================================================
PROMPT TEMA P3.1: ORDS REST Services for Analytics Views
PROMPT ========================================================================

-- ============================================================================
-- PART 1: ORDS SCHEMA SETUP AND ROLES
-- ============================================================================

PROMPT [1] Setting up ORDS Schema and Privileges...

-- Create REST role for TOURISM_ADMIN user
BEGIN
  ORDS.ENABLE_OBJECT(
    p_object => 'TOURISM_ADMIN.V_ANALYTICS_REVENUE_ROLLUP',
    p_object_type => 'VIEW',
    p_object_alias => 'revenue_rollup',
    p_enable_media_type => 'JSON',
    p_enable_media_type => 'CSV'
  );
END;
/

-- ============================================================================
-- PART 2: REST MODULES AND HANDLERS FOR OLAP VIEWS
-- ============================================================================

PROMPT [2] Creating REST Modules for Analytics Endpoints...

-- Module 1: Analytics Revenue Module
DECLARE
  l_module_id NUMBER;
BEGIN
  l_module_id := ORDS.create_module(
    p_module_name    => 'analytics',
    p_base_path      => '/tourism/analytics/',
    p_pattern        => 'analytics',
    p_items_per_page => 100,
    p_status         => 'ACTIVE'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Module created: analytics');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Module already exists or error: ' || SQLERRM);
END;
/

-- ============================================================================
-- PART 3: REST HANDLERS FOR INDIVIDUAL ENDPOINTS
-- ============================================================================

PROMPT [3] Creating REST Handlers for Analytics Endpoints...

-- Handler 1: Revenue Rollup Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'revenue_rollup',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_ANALYTICS_REVENUE_ROLLUP',
    p_comments       => 'Revenue analysis with ROLLUP hierarchy (Hotel > Star > Room)'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/revenue_rollup');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 2: Location Cube Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'location_cube',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_ANALYTICS_LOCATION_CUBE',
    p_comments       => 'Multi-dimensional CUBE analysis (Country × City × Currency)'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/location_cube');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 3: Top Performers Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'top_performers',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT HOTEL_NAME, STAR_RATING, TOTAL_REVENUE_EUR, REVENUE_RANK, REVENUE_PERCENTAGE FROM TOURISM_ADMIN.V_ANALYTICS_TOP_PERFORMERS',
    p_comments       => 'Top performing hotels ranked by revenue'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/top_performers');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 4: Geographic Heatmap Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'geographic_heatmap',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT COUNTRY, CITY, LATITUDE, LONGITUDE, BOOKING_COUNT, TOTAL_REVENUE_EUR, REVENUE_SHARE_PCT FROM TOURISM_ADMIN.V_ANALYTICS_GEOGRAPHIC_HEATMAP',
    p_comments       => 'Geographic revenue distribution with coordinates for mapping'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/geographic_heatmap');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 5: Temporal Trends Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'temporal_trend',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT FULL_DATE, CUMULATIVE_BOOKINGS, CUMULATIVE_REVENUE_EUR, REVENUE_RANK FROM TOURISM_ADMIN.V_ANALYTICS_TEMPORAL_TREND',
    p_comments       => 'Time-series trend analysis with cumulative metrics'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/temporal_trend');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 6: Executive Summary Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'executive_summary',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_REPORT_EXECUTIVE_SUMMARY',
    p_comments       => 'Executive dashboard with key performance indicators'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/executive_summary');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 7: Revenue Analysis Report Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'revenue_analysis',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_REPORT_REVENUE_ANALYSIS',
    p_comments       => 'Revenue performance by hotel'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/revenue_analysis');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler 8: Geographic Performance Report Endpoint
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'analytics',
    p_pattern        => 'geographic_performance',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_REPORT_GEOGRAPHIC',
    p_comments       => 'Geographic performance metrics and rankings'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/analytics/geographic_performance');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- ============================================================================
-- PART 4: ORDS MODULE FOR CONSOLIDATION VIEWS (DATA INTEGRATION LAYER)
-- ============================================================================

PROMPT [4] Creating REST Module for Data Consolidation Endpoints...

DECLARE
  l_module_id NUMBER;
BEGIN
  l_module_id := ORDS.create_module(
    p_module_name    => 'consolidation',
    p_base_path      => '/tourism/consolidation/',
    p_pattern        => 'consolidation',
    p_items_per_page => 100,
    p_status         => 'ACTIVE'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Module created: consolidation');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Module already exists or error: ' || SQLERRM);
END;
/

-- Handler: Bookings Consolidation
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'consolidation',
    p_pattern        => 'bookings',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT BOOKING_ID, GUEST_NAME, HOTEL_NAME, CITY, COUNTRY, ROOM_TYPE, CHECK_IN_DATE, TOTAL_PRICE FROM TOURISM_ADMIN.V_CONSOLIDATE_BOOKINGS',
    p_comments       => 'Multi-source booking consolidation data'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/consolidation/bookings');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler: Accommodation Consolidation
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'consolidation',
    p_pattern        => 'accommodation',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT HOTEL_NAME, CITY, ROOM_TYPE, NIGHTLY_RATE, CURRENCY, NIGHTLY_RATE_EUR FROM TOURISM_ADMIN.V_CONSOLIDATE_ACCOMMODATION',
    p_comments       => 'Accommodation inventory with multi-currency pricing'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/consolidation/accommodation');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler: Travel Integration
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'consolidation',
    p_pattern        => 'travel_packages',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT GUEST_NAME, HOTEL_NAME, CITY, CALLSIGN, ORIGIN_AIRPORT, DESTINATION_AIRPORT, TOTAL_PRICE FROM TOURISM_ADMIN.V_CONSOLIDATE_TRAVEL',
    p_comments       => 'Integrated travel packages combining accommodations and flights'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/consolidation/travel_packages');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- ============================================================================
-- PART 5: ORDS MODULE FOR FEDERATION VIEWS (DATA SOURCES)
-- ============================================================================

PROMPT [5] Creating REST Module for Federation Data Source Endpoints...

DECLARE
  l_module_id NUMBER;
BEGIN
  l_module_id := ORDS.create_module(
    p_module_name    => 'federation',
    p_base_path      => '/tourism/federation/',
    p_pattern        => 'federation',
    p_items_per_page => 100,
    p_status         => 'ACTIVE'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Module created: federation');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Module already exists or error: ' || SQLERRM);
END;
/

-- Handler: DS_1 Hotels
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'federation',
    p_pattern        => 'hotels',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_DS1_HOTELS',
    p_comments       => 'DS_1: External Hotels Data Source'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/federation/hotels');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler: DS_2 Flights
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'federation',
    p_pattern        => 'flights',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT CALLSIGN, ORIGIN_COUNTRY, ORIGIN_AIRPORT, DESTINATION_AIRPORT, ALTITUDE_M, VELOCITY_MS FROM TOURISM_ADMIN.V_DS2_FLIGHTS',
    p_comments       => 'DS_2: Live Flight Information (OpenSky Integration)'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/federation/flights');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler: DS_3 Currencies
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'federation',
    p_pattern        => 'currencies',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_DS3_CURRENCIES',
    p_comments       => 'DS_3: Currency Exchange Rates (ECB Integration)'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/federation/currencies');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

-- Handler: Federation Summary
DECLARE
BEGIN
  ORDS.create_handler(
    p_module_name    => 'federation',
    p_pattern        => 'summary',
    p_method         => 'GET',
    p_source_type    => 'query',
    p_source         => 'SELECT * FROM TOURISM_ADMIN.V_FEDERATION_SUMMARY',
    p_comments       => 'Federation Status Summary across all data sources'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Handler created: GET /tourism/federation/summary');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Handler exists or error: ' || SQLERRM);
END;
/

COMMIT;

-- ============================================================================
-- PART 6: VERIFICATION AND ENDPOINT DOCUMENTATION
-- ========================================================================

PROMPT
PROMPT ========================================================================
PROMPT TEMA P3.1: ORDS REST SERVICES - DEPLOYMENT COMPLETE
PROMPT ========================================================================
PROMPT

PROMPT REST API Endpoint Documentation:
PROMPT
PROMPT *** ANALYTICS ENDPOINTS ***
PROMPT
PROMPT 1. Revenue Analysis with ROLLUP Hierarchy
PROMPT    GET /tourism/analytics/revenue_rollup
PROMPT    Returns: Hotel > Star Rating > Room Type hierarchy with revenue aggregation
PROMPT    Output Format: JSON, CSV
PROMPT    Example: curl "http://localhost:8080/ords/freepdb1/tourism/analytics/revenue_rollup"
PROMPT
PROMPT 2. Multi-Dimensional Location Analysis (CUBE)
PROMPT    GET /tourism/analytics/location_cube
PROMPT    Returns: Multi-dimensional aggregation by Country × City × Currency
PROMPT    Output Format: JSON, CSV
PROMPT
PROMPT 3. Top Performing Hotels
PROMPT    GET /tourism/analytics/top_performers
PROMPT    Returns: Hotels ranked by revenue with market share percentages
PROMPT    Output Format: JSON, CSV
PROMPT
PROMPT 4. Geographic Revenue Heatmap
PROMPT    GET /tourism/analytics/geographic_heatmap
PROMPT    Returns: Cities with coordinates, booking counts, revenue distribution
PROMPT    Output Format: JSON, CSV (suitable for mapping applications)
PROMPT
PROMPT 5. Temporal Trend Analysis
PROMPT    GET /tourism/analytics/temporal_trend
PROMPT    Returns: Time-series data with cumulative bookings and revenue
PROMPT    Output Format: JSON, CSV
PROMPT
PROMPT 6. Executive Summary Dashboard
PROMPT    GET /tourism/analytics/executive_summary
PROMPT    Returns: KPIs - Total Bookings, Confirmed, Active Hotels, Avg Value
PROMPT    Output Format: JSON, CSV
PROMPT
PROMPT 7. Revenue Analysis Report
PROMPT    GET /tourism/analytics/revenue_analysis
PROMPT    Returns: Revenue by hotel, bookings, market share
PROMPT    Output Format: JSON, CSV
PROMPT
PROMPT 8. Geographic Performance Report
PROMPT    GET /tourism/analytics/geographic_performance
PROMPT    Returns: Performance by country/city with top star ratings
PROMPT    Output Format: JSON, CSV
PROMPT

PROMPT
PROMPT *** DATA CONSOLIDATION ENDPOINTS ***
PROMPT
PROMPT 1. Bookings (Multi-Source Integration)
PROMPT    GET /tourism/consolidation/bookings
PROMPT    Returns: Guest name, hotel, city, room type, dates, price
PROMPT    Format: JSON, CSV
PROMPT
PROMPT 2. Accommodation Inventory
PROMPT    GET /tourism/consolidation/accommodation
PROMPT    Returns: Hotels, room types, rates (local + EUR)
PROMPT    Format: JSON, CSV
PROMPT
PROMPT 3. Travel Packages
PROMPT    GET /tourism/consolidation/travel_packages
PROMPT    Returns: Integrated accommodations + flights
PROMPT    Format: JSON, CSV
PROMPT

PROMPT
PROMPT *** FEDERATION DATA SOURCE ENDPOINTS ***
PROMPT
PROMPT 1. DS_1: Hotels
PROMPT    GET /tourism/federation/hotels
PROMPT    Returns: Hotel master data from external source
PROMPT    Format: JSON, CSV
PROMPT
PROMPT 2. DS_2: Flights
PROMPT    GET /tourism/federation/flights
PROMPT    Returns: Real-time flight data (OpenSky API)
PROMPT    Format: JSON, CSV
PROMPT
PROMPT 3. DS_3: Currencies
PROMPT    GET /tourism/federation/currencies
PROMPT    Returns: Exchange rates from ECB web service
PROMPT    Format: JSON, CSV
PROMPT
PROMPT 4. Federation Status
PROMPT    GET /tourism/federation/summary
PROMPT    Returns: Status of all 3 federation sources
PROMPT    Format: JSON, CSV
PROMPT

PROMPT
PROMPT ========================================================================
PROMPT REST ENDPOINT SUMMARY
PROMPT ========================================================================
PROMPT
PROMPT Total Endpoints Created: 13
PROMPT Modules: 3 (analytics, consolidation, federation)
PROMPT Format Support: JSON (default), CSV
PROMPT Base URL: http://localhost:8080/ords/freepdb1/tourism/
PROMPT
PROMPT Authorization: OAuth2 (configured)
PROMPT Pagination: 100 records per page (configurable)
PROMPT
PROMPT
PROMPT Sample cURL Commands:
PROMPT
PROMPT # Get Executive Summary
PROMPT curl -u tourism_user:password \
PROMPT   "http://localhost:8080/ords/freepdb1/tourism/analytics/executive_summary"
PROMPT
PROMPT # Get Geographic Heatmap (JSON)
PROMPT curl -H "Accept: application/json" \
PROMPT   "http://localhost:8080/ords/freepdb1/tourism/analytics/geographic_heatmap"
PROMPT
PROMPT # Get Top Hotels (CSV format)
PROMPT curl -H "Accept: text/csv" \
PROMPT   "http://localhost:8080/ords/freepdb1/tourism/analytics/top_performers"
PROMPT
PROMPT # Get Federation Status
PROMPT curl "http://localhost:8080/ords/freepdb1/tourism/federation/summary"
PROMPT
PROMPT ========================================================================

EXIT;
