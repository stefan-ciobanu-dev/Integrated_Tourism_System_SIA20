-- ============================================================================
-- TEMA L2: Federated Database Architecture - Real Web Sources Integration
-- ============================================================================
-- Implementation of external data source access mechanisms
-- Using: OpenSky Network API (flights), ECB XML (currency), DB_LINK (hotels)
-- ============================================================================

-- ============================================================================
-- PART 1: SETUP - CREATE FEDERATION USER AND DATA STRUCTURES
-- ============================================================================

-- Create dedicated federation schema
CREATE USER L2_FEDERATION IDENTIFIED BY "Federation2025!"
DEFAULT TABLESPACE TOURISM_DATA
TEMPORARY TABLESPACE TOURISM_TEMP;

GRANT CREATE SESSION TO L2_FEDERATION;
GRANT CREATE TABLE TO L2_FEDERATION;
GRANT CREATE VIEW TO L2_FEDERATION;
GRANT CREATE PROCEDURE TO L2_FEDERATION;
GRANT UNLIMITED TABLESPACE TO L2_FEDERATION;
GRANT SELECT ON DS1_HOTELS.HOTELS TO L2_FEDERATION;
GRANT SELECT ON DS1_HOTELS.ROOM_TYPES TO L2_FEDERATION;
GRANT SELECT ON DS1_HOTELS.BOOKINGS_HISTORY TO L2_FEDERATION;

-- Create HTTP session privileges (for REST calls)
BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
    acl => 'http_access.xml',
    description => 'HTTP access for external web services',
    principal => 'L2_FEDERATION',
    is_grant => TRUE,
    privilege => 'connect',
    start_date => SYSDATE,
    end_date => NULL
  );
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
    acl => 'http_access.xml',
    principal => 'L2_FEDERATION',
    is_grant => TRUE,
    privilege => 'resolve',
    start_date => SYSDATE,
    end_date => NULL
  );
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
    acl => 'http_access.xml',
    host => '*',
    lower_port => 80,
    upper_port => 443
  );
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -44416 THEN RAISE; END IF;
END;
/

COMMIT;

-- ============================================================================
-- PART 2: DS_1 HOTELS - DB_LINK SETUP (Remote Database Access)
-- ============================================================================

-- Create Database Link to DS1_HOTELS (simulates remote hotel system)
-- In production: would point to different server/database
CREATE DATABASE LINK HOTELS_REMOTE
  CONNECT TO DS1_HOTELS IDENTIFIED BY "Ds1Hotels2025!"
  USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=FREEPDB1)))';

-- Validate link
SELECT * FROM DS1_HOTELS.HOTELS@HOTELS_REMOTE WHERE ROWNUM <= 1;

-- Create view for remote hotels (simulating external DS_1)
CREATE OR REPLACE VIEW V_DS1_REMOTE_HOTELS AS
SELECT 
  HOTEL_ID,
  HOTEL_NAME,
  CITY,
  COUNTRY,
  STAR_RATING,
  TOTAL_ROOMS,
  YEAR_OPENED,
  SYSDATE as LAST_SYNC
FROM DS1_HOTELS.HOTELS@HOTELS_REMOTE;

-- Create view for remote room types
CREATE OR REPLACE VIEW V_DS1_REMOTE_ROOM_TYPES AS
SELECT 
  ROOM_TYPE_ID,
  HOTEL_ID,
  ROOM_TYPE,
  CAPACITY,
  NIGHTLY_RATE,
  AVAILABLE_ROOMS,
  CURRENCY
FROM DS1_HOTELS.ROOM_TYPES@HOTELS_REMOTE;

-- Create view for remote bookings
CREATE OR REPLACE VIEW V_DS1_REMOTE_BOOKINGS AS
SELECT 
  BOOKING_ID,
  HOTEL_ID,
  GUEST_NAME,
  CHECK_IN_DATE,
  CHECK_OUT_DATE,
  NIGHTS,
  ROOM_TYPE,
  PRICE_PER_NIGHT,
  TOTAL_PRICE,
  BOOKING_STATUS
FROM DS1_HOTELS.BOOKINGS_HISTORY@HOTELS_REMOTE;

-- Test remote access
SELECT COUNT(*) as remote_hotels FROM V_DS1_REMOTE_HOTELS;
SELECT COUNT(*) as remote_room_types FROM V_DS1_REMOTE_ROOM_TYPES;
SELECT COUNT(*) as remote_bookings FROM V_DS1_REMOTE_BOOKINGS;

COMMIT;

-- ============================================================================
-- PART 3: DS_2 FLIGHTS - OPENSKY NETWORK API (Real-Time Data)
-- ============================================================================

-- Create table to cache OpenSky flight data
CREATE TABLE DS2_LIVE_FLIGHTS_CACHE (
  FLIGHT_ID           VARCHAR2(20),
  ICAO24              VARCHAR2(6),           -- Aircraft unique identifier
  CALLSIGN            VARCHAR2(20),          -- Flight callsign (e.g., UAL123)
  ORIGIN_COUNTRY      VARCHAR2(50),
  DEPARTURE_AIRPORT   VARCHAR2(10),
  ARRIVAL_AIRPORT     VARCHAR2(10),
  LATITUDE            NUMBER(8,4),           -- Current position
  LONGITUDE           NUMBER(8,4),           -- Current position
  ALTITUDE_M          NUMBER(10,2),
  VELOCITY_MS         NUMBER(10,2),
  TRUE_TRACK          NUMBER(6,2),
  VERTICAL_RATE_MS    NUMBER(10,2),
  CATEGORY            VARCHAR2(20),          -- Aircraft type
  LAST_POSITION_TIME  TIMESTAMP,
  CAPTURE_TIME        TIMESTAMP DEFAULT SYSDATE,
  CONSTRAINT pk_live_flights PRIMARY KEY (FLIGHT_ID, CAPTURE_TIME)
);

-- Procedure to fetch live flight data from OpenSky Network API
CREATE OR REPLACE PROCEDURE FETCH_OPENSKY_FLIGHTS (
  p_limit NUMBER DEFAULT 100
)
IS
  v_http_req   UTL_HTTP.req;
  v_http_resp  UTL_HTTP.resp;
  v_response   CLOB;
  v_url        VARCHAR2(500) := 'https://opensky-network.org/api/states/all';
  v_chunk      VARCHAR2(4000);
  v_json       JSON_OBJECT_T;
  v_states     JSON_ARRAY_T;
  v_state      JSON_OBJECT_T;
  v_index      NUMBER;
  v_count      NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting OpenSky Network API fetch...');
  
  -- Initialize HTTP request
  v_http_req := UTL_HTTP.BEGIN_REQUEST(v_url, 'GET');
  UTL_HTTP.SET_HEADER(v_http_req, 'User-Agent', 'Tourism-Platform-L2');
  UTL_HTTP.SET_RESPONSE_TIMEOUT(v_http_req, 30);
  
  -- Execute request
  v_http_resp := UTL_HTTP.GET_RESPONSE(v_http_req);
  
  -- Read response
  BEGIN
    LOOP
      UTL_HTTP.READ_LINE(v_http_resp, v_chunk, TRUE);
      v_response := v_response || v_chunk;
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN
      NULL;
  END;
  
  -- Close response
  UTL_HTTP.END_RESPONSE(v_http_resp);
  
  -- Parse JSON response
  v_json := JSON_OBJECT_T.PARSE(v_response);
  v_states := JSON_ARRAY_T(v_json.GET('states'));
  
  -- Insert data into cache table
  FOR v_index IN 0 .. v_states.GET_SIZE() - 1 LOOP
    IF v_count >= p_limit THEN EXIT; END IF;
    
    v_state := JSON_OBJECT_T(v_states.GET(v_index));
    
    INSERT INTO DS2_LIVE_FLIGHTS_CACHE (
      FLIGHT_ID, ICAO24, CALLSIGN, ORIGIN_COUNTRY,
      DEPARTURE_AIRPORT, ARRIVAL_AIRPORT,
      LATITUDE, LONGITUDE, ALTITUDE_M, VELOCITY_MS,
      TRUE_TRACK, VERTICAL_RATE_MS, CATEGORY,
      LAST_POSITION_TIME
    ) VALUES (
      TRIM(v_state.GET_STRING('callsign')) || '_' || v_state.GET_STRING('icao24'),
      v_state.GET_STRING('icao24'),
      TRIM(v_state.GET_STRING('callsign')),
      v_state.GET_STRING('origin_country'),
      NVL(v_state.GET_STRING('estDepartureAirport'), 'UNKNOWN'),
      NVL(v_state.GET_STRING('estArrivalAirport'), 'UNKNOWN'),
      NVL(v_state.GET_NUMBER('latitude'), 0),
      NVL(v_state.GET_NUMBER('longitude'), 0),
      NVL(v_state.GET_NUMBER('baro_altitude'), 0),
      NVL(v_state.GET_NUMBER('velocity'), 0),
      NVL(v_state.GET_NUMBER('true_track'), 0),
      NVL(v_state.GET_NUMBER('vertical_rate'), 0),
      'LIVE_AIRCRAFT',
      TO_TIMESTAMP(v_state.GET_NUMBER('last_position') / 1000, 'YYYY-MM-DD HH24:MI:SS.FF')
    );
    
    v_count := v_count + 1;
  END LOOP;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Fetched ' || v_count || ' live flights from OpenSky Network');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END FETCH_OPENSKY_FLIGHTS;
/

-- Create view for live flights
CREATE OR REPLACE VIEW V_DS2_LIVE_FLIGHTS AS
SELECT 
  ROW_NUMBER() OVER (ORDER BY CAPTURE_TIME DESC) as FLIGHT_ID,
  ICAO24,
  CALLSIGN,
  ORIGIN_COUNTRY,
  DEPARTURE_AIRPORT,
  ARRIVAL_AIRPORT,
  LATITUDE,
  LONGITUDE,
  ALTITUDE_M,
  VELOCITY_MS,
  TRUE_TRACK,
  VERTICAL_RATE_MS,
  LAST_POSITION_TIME,
  CAPTURE_TIME
FROM DS2_LIVE_FLIGHTS_CACHE
WHERE CAPTURE_TIME >= SYSDATE - 1
AND ROWNUM <= 100;

-- Test procedure (if API is accessible)
-- EXEC FETCH_OPENSKY_FLIGHTS(50);

COMMIT;

-- ============================================================================
-- PART 4: DS_3 CURRENCY - ECB XML & exchangerate-api.com
-- ============================================================================

-- Create currency rates table
CREATE TABLE DS3_CURRENCY_RATES (
  CURRENCY_CODE     VARCHAR2(3) PRIMARY KEY,
  CURRENCY_NAME     VARCHAR2(50),
  EUR_RATE          NUMBER(12,6),           -- Rate from EUR
  RATE_DATE         DATE,
  SOURCE            VARCHAR2(50),           -- 'ECB' or 'EXCHANGERATE_API'
  LAST_UPDATE       TIMESTAMP DEFAULT SYSDATE
);

-- Procedure to fetch currency rates from ECB XML (NO AUTH NEEDED)
CREATE OR REPLACE PROCEDURE FETCH_ECB_CURRENCY_RATES
IS
  v_http_req   UTL_HTTP.req;
  v_http_resp  UTL_HTTP.resp;
  v_response   CLOB;
  v_url        VARCHAR2(500) := 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';
  v_chunk      VARCHAR2(4000);
  v_xml_doc    XMLTYPE;
  v_namespaces VARCHAR2(500) := 'xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref"';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fetching ECB currency rates...');
  
  -- Initialize HTTP request
  v_http_req := UTL_HTTP.BEGIN_REQUEST(v_url, 'GET');
  UTL_HTTP.SET_HEADER(v_http_req, 'User-Agent', 'Tourism-Platform');
  UTL_HTTP.SET_RESPONSE_TIMEOUT(v_http_req, 30);
  
  -- Execute request
  v_http_resp := UTL_HTTP.GET_RESPONSE(v_http_req);
  
  -- Read response
  BEGIN
    LOOP
      UTL_HTTP.READ_LINE(v_http_resp, v_chunk, TRUE);
      v_response := v_response || v_chunk;
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN
      NULL;
  END;
  
  -- Close response
  UTL_HTTP.END_RESPONSE(v_http_req);
  
  -- Parse XML and insert rates
  BEGIN
    v_xml_doc := XMLTYPE(v_response);
    
    -- Extract rates from XML using XPath
    INSERT INTO DS3_CURRENCY_RATES (CURRENCY_CODE, CURRENCY_NAME, EUR_RATE, RATE_DATE, SOURCE)
    SELECT 
      EXTRACTVALUE(VALUE(x), '//Cube/@currency'),
      INITCAP(EXTRACTVALUE(VALUE(x), '//Cube/@currency')),
      TO_NUMBER(EXTRACTVALUE(VALUE(x), '//Cube/@rate')),
      TRUNC(SYSDATE),
      'ECB'
    FROM TABLE(XMLSEQUENCE(v_xml_doc.EXTRACT('//Cube[@rate]'))) x
    WHERE EXTRACTVALUE(VALUE(x), '//Cube/@currency') IS NOT NULL;
    
    -- Add EUR itself
    INSERT INTO DS3_CURRENCY_RATES (CURRENCY_CODE, CURRENCY_NAME, EUR_RATE, RATE_DATE, SOURCE)
    VALUES ('EUR', 'Euro', 1.0, TRUNC(SYSDATE), 'ECB');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully fetched ECB currency rates');
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error parsing ECB data: ' || SQLERRM);
      ROLLBACK;
  END;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('HTTP Error: ' || SQLERRM);
END FETCH_ECB_CURRENCY_RATES;
/

-- Procedure to fetch from exchangerate-api.com (with API key optional)
CREATE OR REPLACE PROCEDURE FETCH_EXCHANGERATE_API (
  p_api_key VARCHAR2 DEFAULT NULL
)
IS
  v_http_req   UTL_HTTP.req;
  v_http_resp  UTL_HTTP.resp;
  v_response   CLOB;
  v_url        VARCHAR2(500);
  v_chunk      VARCHAR2(4000);
  v_json       JSON_OBJECT_T;
  v_rates      JSON_OBJECT_T;
  v_rate_keys  JSON_KEY_LIST;
  v_i          NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Fetching exchangerate-api.com rates...');
  
  IF p_api_key IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Note: No API key provided. Using ECB rates instead.');
    RETURN;
  END IF;
  
  v_url := 'https://v6.exchangerate-api.com/v6/' || p_api_key || '/latest/EUR';
  
  -- Initialize HTTP request
  v_http_req := UTL_HTTP.BEGIN_REQUEST(v_url, 'GET');
  UTL_HTTP.SET_HEADER(v_http_req, 'User-Agent', 'Tourism-Platform');
  UTL_HTTP.SET_RESPONSE_TIMEOUT(v_http_req, 30);
  
  -- Execute request
  v_http_resp := UTL_HTTP.GET_RESPONSE(v_http_req);
  
  -- Read response
  BEGIN
    LOOP
      UTL_HTTP.READ_LINE(v_http_resp, v_chunk, TRUE);
      v_response := v_response || v_chunk;
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN
      NULL;
  END;
  
  -- Close response
  UTL_HTTP.END_RESPONSE(v_http_resp);
  
  -- Parse JSON response
  v_json := JSON_OBJECT_T.PARSE(v_response);
  v_rates := JSON_OBJECT_T(v_json.GET('rates'));
  v_rate_keys := v_rates.GET_KEYS();
  
  -- Insert rates into table
  FOR v_i IN 1 .. v_rate_keys.COUNT LOOP
    INSERT INTO DS3_CURRENCY_RATES (CURRENCY_CODE, CURRENCY_NAME, EUR_RATE, RATE_DATE, SOURCE)
    VALUES (
      v_rate_keys(v_i),
      v_rate_keys(v_i),
      v_rates.GET_NUMBER(v_rate_keys(v_i)),
      TRUNC(SYSDATE),
      'EXCHANGERATE_API'
    );
  END LOOP;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Successfully fetched ' || v_rate_keys.COUNT || ' currency rates');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END FETCH_EXCHANGERATE_API;
/

-- Create view for currency rates
CREATE OR REPLACE VIEW V_DS3_CURRENCY_RATES AS
SELECT 
  CURRENCY_CODE,
  CURRENCY_NAME,
  EUR_RATE,
  RATE_DATE,
  SOURCE,
  LAST_UPDATE
FROM DS3_CURRENCY_RATES
WHERE RATE_DATE = TRUNC(SYSDATE);

-- Initialize with ECB rates (first time setup)
EXEC FETCH_ECB_CURRENCY_RATES();

COMMIT;

-- ============================================================================
-- PART 5: DS_3 BOOKINGS - INTEGRATED FROM EXTERNAL SOURCES
-- ============================================================================

-- Create bookings table combining DS_1 hotels + DS_2 flights + DS_3 currency
CREATE TABLE DS3_INTEGRATED_BOOKINGS (
  BOOKING_ID          VARCHAR2(20) PRIMARY KEY,
  BOOKING_DATE        DATE,
  GUEST_ID            VARCHAR2(10),
  HOTEL_ID            VARCHAR2(10),
  HOTEL_NAME          VARCHAR2(100),
  FLIGHT_ID           VARCHAR2(20),
  FLIGHT_CALLSIGN     VARCHAR2(20),
  DEPARTURE_AIRPORT   VARCHAR2(10),
  ARRIVAL_AIRPORT     VARCHAR2(10),
  CHECK_IN_DATE       DATE,
  CHECK_OUT_DATE      DATE,
  NIGHTS              NUMBER,
  ROOM_PRICE_PER_NIGHT NUMBER(10,2),
  FLIGHT_PRICE        NUMBER(10,2),
  CURRENCY_CODE       VARCHAR2(3),
  EUR_RATE            NUMBER(12,6),
  BOOKING_TOTAL_EUR   NUMBER(12,2),
  BOOKING_TOTAL_ORIG  NUMBER(12,2),
  PAYMENT_STATUS      VARCHAR2(20),
  CREATED_DATE        TIMESTAMP DEFAULT SYSDATE
);

-- View for integrated bookings
CREATE OR REPLACE VIEW V_DS3_INTEGRATED_BOOKINGS AS
SELECT 
  BOOKING_ID,
  BOOKING_DATE,
  GUEST_ID,
  HOTEL_NAME,
  FLIGHT_CALLSIGN || ' (' || DEPARTURE_AIRPORT || '→' || ARRIVAL_AIRPORT || ')' as FLIGHT,
  CHECK_IN_DATE,
  CHECK_OUT_DATE,
  NIGHTS,
  ROOM_PRICE_PER_NIGHT,
  FLIGHT_PRICE,
  CURRENCY_CODE,
  EUR_RATE,
  BOOKING_TOTAL_EUR,
  ROUND(BOOKING_TOTAL_EUR * EUR_RATE, 2) as BOOKING_TOTAL_ORIGINAL_CURRENCY,
  PAYMENT_STATUS
FROM DS3_INTEGRATED_BOOKINGS
ORDER BY BOOKING_DATE DESC;

COMMIT;

-- ============================================================================
-- PART 6: FEDERATION VIEWS - UNIFIED ACCESS LAYER
-- ============================================================================

-- View 1: All hotels from remote source
CREATE OR REPLACE VIEW V_L2_HOTELS AS
SELECT 
  'DS_1_REMOTE' as SOURCE,
  HOTEL_ID,
  HOTEL_NAME,
  CITY,
  COUNTRY,
  STAR_RATING,
  TOTAL_ROOMS,
  'DATABASE_LINK' as ACCESS_METHOD,
  LAST_SYNC
FROM V_DS1_REMOTE_HOTELS;

-- View 2: All flights from API
CREATE OR REPLACE VIEW V_L2_FLIGHTS AS
SELECT 
  'DS_2_OPENSKY' as SOURCE,
  FLIGHT_ID,
  CALLSIGN,
  ORIGIN_COUNTRY,
  DEPARTURE_AIRPORT,
  ARRIVAL_AIRPORT,
  LATITUDE,
  LONGITUDE,
  ALTITUDE_M,
  VELOCITY_MS,
  'REST_API' as ACCESS_METHOD,
  CAPTURE_TIME
FROM V_DS2_LIVE_FLIGHTS;

-- View 3: All currencies from real source
CREATE OR REPLACE VIEW V_L2_CURRENCIES AS
SELECT 
  'DS_3_ECB' as SOURCE,
  CURRENCY_CODE,
  CURRENCY_NAME,
  EUR_RATE,
  RATE_DATE,
  SOURCE as RATE_SOURCE,
  'HTTP_XML' as ACCESS_METHOD,
  LAST_UPDATE
FROM V_DS3_CURRENCY_RATES;

-- View 4: Integrated bookings
CREATE OR REPLACE VIEW V_L2_COMPLETE_BOOKINGS AS
SELECT 
  'DS_3_INTEGRATED' as SOURCE,
  BOOKING_ID,
  HOTEL_NAME,
  FLIGHT_CALLSIGN,
  DEPARTURE_AIRPORT,
  ARRIVAL_AIRPORT,
  BOOKING_TOTAL_EUR,
  CURRENCY_CODE,
  EUR_RATE,
  BOOKING_TOTAL_ORIG,
  PAYMENT_STATUS,
  'MULTI_SOURCE' as ACCESS_METHOD,
  CREATED_DATE
FROM DS3_INTEGRATED_BOOKINGS;

COMMIT;

-- ============================================================================
-- PART 7: TEST FEDERATION QUERIES
-- ============================================================================

-- Test 1: Access remote hotels via DB_LINK
SELECT COUNT(*) as REMOTE_HOTELS_COUNT FROM V_L2_HOTELS;

-- Test 2: Check if OpenSky flights are available
SELECT COUNT(*) as LIVE_FLIGHTS_COUNT FROM V_L2_FLIGHTS;

-- Test 3: Verify currency rates from real source
SELECT COUNT(*) as CURRENCY_CODES FROM V_L2_CURRENCIES;

-- Test 4: Cross-source integration
SELECT 
  h.HOTEL_NAME,
  COUNT(DISTINCT b.BOOKING_ID) as BOOKINGS,
  SUM(b.BOOKING_TOTAL_EUR) as REVENUE_EUR
FROM V_L2_HOTELS h
LEFT JOIN DS3_INTEGRATED_BOOKINGS b ON h.HOTEL_ID = b.HOTEL_ID
GROUP BY h.HOTEL_NAME
HAVING COUNT(DISTINCT b.BOOKING_ID) > 0;

COMMIT;

-- ============================================================================
-- PART 8: GRANTS FOR FEDERATION ACCESS  
-- ============================================================================

GRANT SELECT ON V_DS1_REMOTE_HOTELS TO PUBLIC;
GRANT SELECT ON V_DS1_REMOTE_ROOM_TYPES TO PUBLIC;
GRANT SELECT ON V_DS1_REMOTE_BOOKINGS TO PUBLIC;
GRANT SELECT ON V_DS2_LIVE_FLIGHTS_CACHE TO PUBLIC;
GRANT SELECT ON V_DS2_LIVE_FLIGHTS TO PUBLIC;
GRANT SELECT ON DS3_CURRENCY_RATES TO PUBLIC;
GRANT SELECT ON V_DS3_CURRENCY_RATES TO PUBLIC;
GRANT SELECT ON DS3_INTEGRATED_BOOKINGS TO PUBLIC;
GRANT SELECT ON V_L2_HOTELS TO PUBLIC;
GRANT SELECT ON V_L2_FLIGHTS TO PUBLIC;
GRANT SELECT ON V_L2_CURRENCIES TO PUBLIC;
GRANT SELECT ON V_L2_COMPLETE_BOOKINGS TO PUBLIC;

COMMIT;

-- ============================================================================
-- INSTALLATION COMPLETE
-- ============================================================================
-- Summary:
-- - DS_1 (Hotels): DB_LINK to remote hotel system
-- - DS_2 (Flights): HTTP API from OpenSky Network (real live data)
-- - DS_3 (Currency): HTTP XML from ECB (European Central Bank)
-- - DS_3 (Bookings): Integrated from above sources
-- - Federation Views: Unified access layer
--
-- Next: TEMA L3 - Create OLAP analytical views
-- ============================================================================
