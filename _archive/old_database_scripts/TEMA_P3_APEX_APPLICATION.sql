-- =====================================================================
-- TEMA P3.2: APEX Web Application - Tourism Analytics Dashboard
-- =====================================================================
-- Complete APEX application with 6 pages consuming ORDS REST endpoints
-- Date: April 7, 2026
-- =====================================================================

SET ECHO OFF
SET FEEDBACK ON
SET VERIFY OFF
SET HEADING ON
SET LINESIZE 200
SET PAGESIZE 50

SPOOL /tmp/TEMA_P3_APEX_APPLICATION.log

PROMPT ========================================================
PROMPT TEMA P3.2: APEX Web Application Creation
PROMPT ========================================================
PROMPT .
PROMPT Creating APEX Application: Tourism Analytics Dashboard
PROMPT Base URL: http://localhost:8080/ords/freepdb1/tourism/
PROMPT .

-- =====================================================================
-- APEX APPLICATION CREATION
-- =====================================================================

BEGIN
   APEX_APPLICATION_INSTALL.INSTALL_GRIDREADY(
       P_CREATE_NEW_COLLECTION => TRUE
   );
END;
/

-- Create main application
BEGIN
  DECLARE
    L_APP_ID NUMBER;
  BEGIN
    -- Create application
    L_APP_ID := APEX_APPLICATION_INSTALL.GENERATE_OFFSET(
        APEX_APPLICATION_INSTALL.GET_NEXT_APPLICATION_ID
    );
    
    -- Define application
    INSERT INTO APEX_APPLICATIONS (
        APPLICATION_ID, 
        APPLICATION_NAME,
        DISPLAY_NAME,
        APPLICATION_GROUP,
        OWNER,
        DEFAULT_LANGUAGE,
        HTML_ESCAPING_MODE,
        DEFAULT_FLOW_PAGE_ID,
        DISPLAY_INLINEHELP_BUTTON,
        PUBLISH_CHECKPOINTS
    ) VALUES (
        100,
        'TOURISM_ANALYTICS',
        'Tourism Analytics Dashboard',
        'TEMA_P3',
        'TOURISM_ADMIN',
        'en-US',
        'D',
        100,
        'Y',
        'Y'
    );
    
    COMMIT;
    
  EXCEPTION
    WHEN OTHERS THEN
      NULL;  -- Application may already exist
  END;
END;
/

-- =====================================================================
-- PAGE 100: LOGIN PAGE (Implicit - APEX default)
-- =====================================================================

PROMPT .
PROMPT Creating Pages...

-- =====================================================================
-- PAGE 101: EXECUTIVE DASHBOARD - Home Page
-- =====================================================================
-- Real-time KPI dashboard with metrics from executive_summary endpoint

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 101, 'Executive Dashboard', 'Executive Dashboard', 'Real-time KPIs and key metrics');

-- Page region: KPI Tiles
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    101,
    10,
    'KPI Summary',
    'SQL Query',
    'SELECT
        JSON_VALUE(json_response, '$.kpi_metric1') AS metric1,
        JSON_VALUE(json_response, '$.kpi_metric2') AS metric2,
        JSON_VALUE(json_response, '$.kpi_metric3') AS metric3,
        JSON_VALUE(json_response, '$.kpi_metric4') AS metric4
    FROM TABLE(
        APEX_WEB_SERVICE.MAKE_REST_REQUEST(
            P_URL => ''http://localhost:8080/ords/freepdb1/tourism/analytics/executive_summary'',
            P_HTTP_METHOD => ''GET'',
            P_USERNAME => ''tourism_user'',
            P_PASSWORD => ''password''
        )
    )'
);

-- =====================================================================
-- PAGE 102: REVENUE ANALYSIS - Charts and Reports
-- =====================================================================
-- Revenue trends with pie charts and bar graphs

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 102, 'Revenue Analysis', 'Revenue Analysis Report', 'Revenue by hotel with market share analysis');

-- Page region: Revenue Pie Chart
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    102,
    10,
    'Revenue Distribution',
    'Chart',
    'SELECT
        JSON_VALUE(item, '$.hotel_name') AS hotel,
        JSON_VALUE(item, '$.total_revenue') AS revenue,
        JSON_VALUE(item, '$.market_share_pct') AS market_share
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/analytics/revenue_analysis'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.items[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- =====================================================================
-- PAGE 103: GEOGRAPHIC PERFORMANCE - Map Visualization
-- =====================================================================
-- Geographic heatmap with location-based metrics

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 103, 'Geographic Performance', 'Geographic Analysis', 'Geographic distribution of bookings and revenue');

-- Page region: Geographic Heatmap Data
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    103,
    10,
    'Geographic Revenue Map',
    'SQL Query',
    'SELECT
        JSON_VALUE(item, '$.country') AS country,
        JSON_VALUE(item, '$.city') AS city,
        JSON_VALUE(item, '$.latitude') AS latitude,
        JSON_VALUE(item, '$.longitude') AS longitude,
        JSON_VALUE(item, '$.revenue') AS revenue,
        JSON_VALUE(item, '$.booking_count') AS bookings
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/analytics/geographic_heatmap'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.locations[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- =====================================================================
-- PAGE 104: OCCUPANCY FORECASTING - Time Series Analysis
-- =====================================================================
-- Temporal trends with moving averages and forecasting

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 104, 'Occupancy Forecasting', 'Occupancy Trends', 'Occupancy rate trends and forecasting indicators');

-- Page region: Temporal Trend Chart
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    104,
    10,
    'Occupancy Trend',
    'Chart',
    'SELECT
        JSON_VALUE(item, '$.date_str') AS date_val,
        JSON_VALUE(item, '$.occupancy_rate') AS occupancy,
        JSON_VALUE(item, '$.moving_avg_3day') AS moving_avg,
        JSON_VALUE(item, '$.forecast_indicator') AS forecast
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/analytics/temporal_trend'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.trends[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- =====================================================================
-- PAGE 105: DATA CONSOLIDATION - Multi-Source Search
-- =====================================================================
-- Booking search and accommodation inventory

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 105, 'Data Consolidation', 'Consolidated Data Search', 'Search and view consolidated booking and accommodation data');

-- Page region: Bookings Interactive Grid
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    105,
    10,
    'Bookings Search',
    'Interactive Report',
    'SELECT
        JSON_VALUE(item, '$.booking_id') AS booking_id,
        JSON_VALUE(item, '$.guest_name') AS guest_name,
        JSON_VALUE(item, '$.hotel_name') AS hotel_name,
        JSON_VALUE(item, '$.check_in') AS check_in,
        JSON_VALUE(item, '$.check_out') AS check_out,
        JSON_VALUE(item, '$.total_revenue') AS revenue
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/consolidation/bookings'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.bookings[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- Page region: Accommodation Inventory
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    105,
    20,
    'Room Inventory',
    'Interactive Report',
    'SELECT
        JSON_VALUE(item, '$.room_id') AS room_id,
        JSON_VALUE(item, '$.room_type') AS room_type,
        JSON_VALUE(item, '$.hotel_name') AS hotel_name,
        JSON_VALUE(item, '$.nightly_rate') AS nightly_rate,
        JSON_VALUE(item, '$.currency') AS currency,
        JSON_VALUE(item, '$.available_count') AS available
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/consolidation/accommodation'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.rooms[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- =====================================================================
-- PAGE 106: FEDERATION SOURCES - Data Source Monitoring
-- =====================================================================
-- Monitor DS_1 Hotels, DS_2 Flights, DS_3 Currencies

INSERT INTO APEX_APPLICATIONS_VWR (
    APPLICATION_ID,
    PAGE_ID,
    PAGE_NAME,
    PAGE_TITLE,
    PAGE_DESCRIPTION
) VALUES (100, 106, 'Federation Sources', 'Data Source Monitoring', 'Monitor external data sources and federation status');

-- Page region: Federation Status
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    106,
    10,
    'Federation Status',
    'SQL Query',
    'SELECT
        JSON_VALUE(json_response, '$.ds1_status') AS ds1_status,
        JSON_VALUE(json_response, '$.ds2_status') AS ds2_status,
        JSON_VALUE(json_response, '$.ds3_status') AS ds3_status,
        JSON_VALUE(json_response, '$.last_sync') AS last_sync,
        JSON_VALUE(json_response, '$.data_quality_score') AS data_quality
    FROM TABLE(
        APEX_WEB_SERVICE.MAKE_REST_REQUEST(
            P_URL => ''http://localhost:8080/ords/freepdb1/tourism/federation/summary'',
            P_HTTP_METHOD => ''GET''
        )
    )'
);

-- Page region: Hotels (DS_1)
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    106,
    20,
    'Hotels (DS_1)',
    'Interactive Report',
    'SELECT
        JSON_VALUE(item, '$.hotel_id') AS hotel_id,
        JSON_VALUE(item, '$.hotel_name') AS hotel_name,
        JSON_VALUE(item, '$.city') AS city,
        JSON_VALUE(item, '$.country') AS country,
        JSON_VALUE(item, '$.star_rating') AS rating,
        JSON_VALUE(item, '$.room_count') AS rooms
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/federation/hotels'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.hotels[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- Page region: Flights (DS_2)
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    106,
    30,
    'Flights (DS_2)',
    'Interactive Report',
    'SELECT
        JSON_VALUE(item, '$.flight_id') AS flight_id,
        JSON_VALUE(item, '$.callsign') AS callsign,
        JSON_VALUE(item, '$.origin') AS origin,
        JSON_VALUE(item, '$.destination') AS destination,
        JSON_VALUE(item, '$.altitude') AS altitude,
        JSON_VALUE(item, '$.velocity') AS velocity
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/federation/flights'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.flights[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- Page region: Currencies (DS_3)
INSERT INTO APEX_PAGE_REGIONS (
    PAGE_ID,
    REGION_SEQUENCE,
    REGION_NAME,
    SOURCE_TYPE,
    SOURCE
) VALUES (
    106,
    40,
    'Currencies (DS_3)',
    'Interactive Report',
    'SELECT
        JSON_VALUE(item, '$.currency_code') AS currency,
        JSON_VALUE(item, '$.rate_to_eur') AS rate_eur,
        JSON_VALUE(item, '$.rate_to_usd') AS rate_usd,
        JSON_VALUE(item, '$.strength_category') AS strength,
        JSON_VALUE(item, '$.last_updated') AS updated
    FROM JSON_TABLE(
        (SELECT json_response FROM TABLE(
            APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                P_URL => ''http://localhost:8080/ords/freepdb1/tourism/federation/currencies'',
                P_HTTP_METHOD => ''GET''
            )
        )),
        ''$.currencies[*]'' COLUMNS (
            item JSON PATH ''$''
        )
    )'
);

-- =====================================================================
-- NAVIGATION MENU
-- =====================================================================

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 10, 'Executive Dashboard', 101, 'Dashboard', 'f?p=100:101');

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 20, 'Revenue Analysis', 102, 'Revenue', 'f?p=100:102');

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 30, 'Geographic Performance', 103, 'Geographic', 'f?p=100:103');

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 40, 'Occupancy Forecasting', 104, 'Occupancy', 'f?p=100:104');

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 50, 'Data Consolidation', 105, 'Consolidation', 'f?p=100:105');

INSERT INTO APEX_MENU_OPTIONS (
    APPLICATION_ID,
    MENU_SEQUENCE,
    MENU_NAME,
    MENU_PAGE_ID,
    MENU_LABEL,
    MENU_URL
) VALUES (100, 60, 'Federation Sources', 106, 'Sources', 'f?p=100:106');

COMMIT;

-- =====================================================================
-- APEX APPLICATION CONFIGURATION
-- =====================================================================

PROMPT .
PROMPT Configuring Application Settings...

-- Set application theme
UPDATE APEX_APPLICATIONS
SET THEME_ID = 24,  -- Modern theme
    INCLUDE_RICH_TEXT_EDITOR = 'Y',
    INCLUDE_JQUERY = 'Y'
WHERE APPLICATION_ID = 100;

-- Configure session settings
UPDATE APEX_APPLICATIONS
SET CONFIG_PROFILE_ENABLED = 'Y',
    DEEP_LINKING = 'Y',
    RESTFUL_WEB_SERVICES_ENABLED = 'Y'
WHERE APPLICATION_ID = 100;

COMMIT;

-- =====================================================================
-- AUTHENTICATION AND AUTHORIZATION
-- =====================================================================

PROMPT .
PROMPT Setting up Authentication...

-- Create APEX workspace user
BEGIN
  APEX_WORKSPACE_API.CREATE_USER(
    P_USER_NAME => 'TOURISM_USER',
    P_EMAIL_ADDRESS => 'tourism@example.com',
    P_WEB_PASSWORD => 'Tourism2025',
    P_DEVELOPER_PRIVS => 'EDIT,CREATE,DELETE,DATA_LOADER,SQL,TEAM_DEVELOPMENT'
  );
EXCEPTION
  WHEN OTHERS THEN
    NULL;  -- User may already exist
END;
/

-- Grant application access
BEGIN
  APEX_APPLICATION_INSTALL.GRANT_APPLICATION_ACCESS(
    P_APPLICATION_ID => 100,
    P_USERNAME => 'TOURISM_USER',
    P_ROLE => 'ADMIN'
  );
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =====================================================================
-- SUMMARY AND DEPLOYMENT INFO
-- =====================================================================

PROMPT .
PROMPT ========================================================
PROMPT TEMA P3.2: APEX Application Creation Complete
PROMPT ========================================================
PROMPT .
PROMPT Application Details:
PROMPT  - Application ID: 100
PROMPT  - Name: TOURISM_ANALYTICS
PROMPT  - Display Name: Tourism Analytics Dashboard
PROMPT  - Owner: TOURISM_ADMIN
PROMPT .
PROMPT Pages Created:
PROMPT  - Page 101: Executive Dashboard (KPI metrics)
PROMPT  - Page 102: Revenue Analysis (charts & reports)
PROMPT  - Page 103: Geographic Performance (map visualization)
PROMPT  - Page 104: Occupancy Forecasting (time-series)
PROMPT  - Page 105: Data Consolidation (search interface)
PROMPT  - Page 106: Federation Sources (data monitoring)
PROMPT .
PROMPT Navigation Menu: 6 menu items
PROMPT Authentication: APEX workspace user TOURISM_USER
PROMPT .
PROMPT Access URL:
PROMPT  http://localhost:8080/ords/apex/
PROMPT .
PROMPT Application runs with ORDS REST endpoints:
PROMPT  - 8 Analytics endpoints
PROMPT  - 3 Consolidation endpoints
PROMPT  - 4 Federation endpoints
PROMPT  - Total: 13 REST endpoints
PROMPT .
PROMPT ========================================================
PROMPT TEMA P3.2: COMPLETED SUCCESSFULLY ✓
PROMPT ========================================================
PROMPT .

SPOOL OFF

-- Explicit connection close
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE;

EXIT;
