-- ============================================================================
-- TEMA L2: ORDS REST Data Services - Federated Endpoints
-- ============================================================================
-- RESTful API endpoints for accessing federated data sources
-- Execute as ORDS admin or through ORDS configuration
-- ============================================================================

-- ============================================================================
-- ENDPOINT 1: Hotels (Remote via DB_LINK)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'hotels',
    p_base_path => '/api/hotels/',
    p_pattern => 'all',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM V_L2_HOTELS ORDER BY HOTEL_NAME',
    p_comments => 'Get all hotels from remote source via DB_LINK'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'hotels',
    p_base_path => '/api/hotels/',
    p_pattern => ':id',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM V_L2_HOTELS WHERE HOTEL_ID = :id',
    p_comments => 'Get specific hotel by ID'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 2: Live Flights (OpenSky Network API)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'flights',
    p_base_path => '/api/flights/',
    p_pattern => 'live',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM V_L2_FLIGHTS WHERE ROWNUM <= 50 ORDER BY CAPTURE_TIME DESC',
    p_comments => 'Get recent live flights from OpenSky Network'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'flights',
    p_base_path => '/api/flights/',
    p_pattern => 'search',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM V_L2_FLIGHTS WHERE DEPARTURE_AIRPORT = :dep OR ARRIVAL_AIRPORT = :arr ORDER BY CAPTURE_TIME DESC',
    p_comments => 'Search flights by departure or arrival airport'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 3: Currency Rates (ECB - Real-Time)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'currency',
    p_base_path => '/api/currency/',
    p_pattern => 'rates',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT CURRENCY_CODE, CURRENCY_NAME, EUR_RATE FROM V_L2_CURRENCIES ORDER BY CURRENCY_CODE',
    p_comments => 'Get all currency exchange rates relative to EUR'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'currency',
    p_base_path => '/api/currency/',
    p_pattern => ':code',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT CURRENCY_CODE, CURRENCY_NAME, EUR_RATE, RATE_DATE, SOURCE FROM V_L2_CURRENCIES WHERE CURRENCY_CODE = UPPER(:code)',
    p_comments => 'Get specific currency rate'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 4: Integrated Bookings (Multi-Source)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'bookings',
    p_base_path => '/api/bookings/',
    p_pattern => 'all',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM V_L2_COMPLETE_BOOKINGS ORDER BY CREATED_DATE DESC',
    p_comments => 'Get all integrated bookings'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'bookings',
    p_base_path => '/api/bookings/',
    p_pattern => 'by-hotel/:hotel_id',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT * FROM DS3_INTEGRATED_BOOKINGS WHERE HOTEL_ID = :hotel_id ORDER BY BOOKING_DATE DESC',
    p_comments => 'Get bookings for specific hotel'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'bookings',
    p_base_path => '/api/bookings/',
    p_pattern => 'by-city/:city',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => 'SELECT b.* FROM DS3_INTEGRATED_BOOKINGS b JOIN V_L2_HOTELS h ON b.HOTEL_ID = h.HOTEL_ID WHERE UPPER(h.CITY) = UPPER(:city) ORDER BY b.BOOKING_DATE DESC',
    p_comments => 'Get bookings for specific city'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 5: Federation Status (Health Check)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'federation',
    p_base_path => '/api/federation/',
    p_pattern => 'status',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => q'[
SELECT 
  'Hotels (DB_LINK)' as SOURCE,
  (SELECT COUNT(*) FROM V_L2_HOTELS) as RECORD_COUNT,
  'Database Link to DS1_HOTELS' as ACCESS_METHOD,
  'ACTIVE' as STATUS
FROM DUAL
UNION ALL
SELECT 
  'Flights (OpenSky API)',
  COALESCE((SELECT COUNT(*) FROM V_L2_FLIGHTS), 0),
  'REST API HTTP',
  CASE WHEN (SELECT COUNT(*) FROM V_L2_FLIGHTS) > 0 THEN 'ACTIVE' ELSE 'INACTIVE' END
FROM DUAL
UNION ALL
SELECT 
  'Currency (ECB XML)',
  (SELECT COUNT(*) FROM V_L2_CURRENCIES),
  'HTTP XML Parser',
  CASE WHEN (SELECT COUNT(*) FROM V_L2_CURRENCIES) > 0 THEN 'ACTIVE' ELSE 'INACTIVE' END
FROM DUAL
UNION ALL
SELECT 
  'Bookings (Integrated)',
  COALESCE((SELECT COUNT(*) FROM DS3_INTEGRATED_BOOKINGS), 0),
  'Multi-Source Integration',
  CASE WHEN (SELECT COUNT(*) FROM DS3_INTEGRATED_BOOKINGS) > 0 THEN 'ACTIVE' ELSE 'INACTIVE' END
FROM DUAL
    ]',
    p_comments => 'Get federation layer health and status'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 6: Advanced Analytics (OLAP Preview)
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'analytics',
    p_base_path => '/api/analytics/',
    p_pattern => 'revenue-by-hotel',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => q'[
SELECT 
  h.HOTEL_NAME,
  h.CITY,
  COUNT(DISTINCT b.BOOKING_ID) as BOOKING_COUNT,
  SUM(b.BOOKING_TOTAL_EUR) as TOTAL_REVENUE_EUR,
  ROUND(AVG(b.BOOKING_TOTAL_EUR), 2) as AVG_BOOKING_VALUE_EUR,
  MAX(b.BOOKING_DATE) as LAST_BOOKING_DATE
FROM V_L2_HOTELS h
LEFT JOIN DS3_INTEGRATED_BOOKINGS b ON h.HOTEL_ID = b.HOTEL_ID
GROUP BY h.HOTEL_NAME, h.CITY
ORDER BY TOTAL_REVENUE_EUR DESC
    ]',
    p_comments => 'Revenue analysis by hotel'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'analytics',
    p_base_path => '/api/analytics/',
    p_pattern => 'routes-analysis',
    p_method => 'GET',
    p_source_type => ORDS.source_type_query,
    p_source => q'[
SELECT 
  DEPARTURE_AIRPORT,
  ARRIVAL_AIRPORT,
  COUNT(DISTINCT FLIGHT_ID) as FLIGHT_COUNT,
  COUNT(DISTINCT BOOKING_ID) as BOOKINGS,
  SUM(FLIGHT_PRICE) as FLIGHT_REVENUE_EUR
FROM DS3_INTEGRATED_BOOKINGS
GROUP BY DEPARTURE_AIRPORT, ARRIVAL_AIRPORT
ORDER BY FLIGHT_REVENUE_EUR DESC
    ]',
    p_comments => 'Flight route analysis'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT 7: Data Synchronization
-- ============================================================================

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'sync',
    p_base_path => '/api/sync/',
    p_pattern => 'refresh-flights',
    p_method => 'POST',
    p_source_type => ORDS.source_type_plsql,
    p_source => 'BEGIN FETCH_OPENSKY_FLIGHTS(100); DBMS_OUTPUT.PUT_LINE(''Flights refreshed''); END;',
    p_comments => 'Refresh live flight data from OpenSky Network'
  );
  COMMIT;
END;
/

BEGIN
  ORDS.DEFINE_SERVICE(
    p_module_name => 'sync',
    p_base_path => '/api/sync/',
    p_pattern => 'refresh-currency',
    p_method => 'POST',
    p_source_type => ORDS.source_type_plsql,
    p_source => 'BEGIN FETCH_ECB_CURRENCY_RATES(); DBMS_OUTPUT.PUT_LINE(''Currency rates refreshed''); END;',
    p_comments => 'Refresh currency rates from ECB'
  );
  COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT TESTING GUIDE
-- ============================================================================
/*
Using curl or REST client (e.g., Postman):

1. Hotels:
   GET http://localhost:8181/ords/api/hotels/all
   GET http://localhost:8181/ords/api/hotels/H001

2. Flights (Live):
   GET http://localhost:8181/ords/api/flights/live
   GET http://localhost:8181/ords/api/flights/search?dep=JFK&arr=BCN

3. Currency Rates:
   GET http://localhost:8181/ords/api/currency/rates
   GET http://localhost:8181/ords/api/currency/USD

4. Bookings:
   GET http://localhost:8181/ords/api/bookings/all
   GET http://localhost:8181/ords/api/bookings/by-city/Barcelona

5. Federation Status:
   GET http://localhost:8181/ords/api/federation/status

6. Analytics:
   GET http://localhost:8181/ords/api/analytics/revenue-by-hotel
   GET http://localhost:8181/ords/api/analytics/routes-analysis

7. Refresh Data (POST requests):
   POST http://localhost:8181/ords/api/sync/refresh-flights
   POST http://localhost:8181/ords/api/sync/refresh-currency
*/

COMMIT;
