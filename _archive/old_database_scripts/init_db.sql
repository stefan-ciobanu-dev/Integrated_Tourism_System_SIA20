-- ============================================================================
-- Tourism Analysis Platform - Database Initialization Script
-- Platforma de analiza a turismului - Script de inițializare bază de date
--
-- Purpose: Initial database setup when container starts
-- Executed by: Docker entrypoint during container initialization
--
-- Tasks performed:
--   1. Create tablespaces for application data
--   2. Create TOURISM_ADMIN user with required privileges
--   3. Create directories for data import/export
--   4. Create initial schema objects
--   5. Grant necessary system privileges
--
-- Error Handling: Scripts use SET statements to continue on error where appropriate
-- ============================================================================

-- ============================================================================
-- Session Settings
-- ============================================================================

SET ECHO ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 200
SET PAGESIZE 50
SET VERIFY ON
SET TIMING ON

-- Enable output to see progress
SPOOL /tmp/init_db.log

-- ============================================================================
-- PRE-INITIALIZATION CHECKS
-- ============================================================================

PROMPT
PROMPT ========================================================================
PROMPT Tourism Analysis Platform - Database Initialization
PROMPT ========================================================================
PROMPT

-- Display current database information
COL NAME FORMAT A20
COL OPEN_CURSORS FORMAT 9999
COL DB_VERSION FORMAT A20

SELECT
    NAME,
    OPEN_CURSORS,
    DATABASE_VERSION AS DB_VERSION
FROM V$DATABASE
JOIN V$PARAMETER ON 1=1
WHERE NAME = 'open_cursors';

-- ============================================================================
-- PART 1: CREATE TABLESPACES
-- ============================================================================

PROMPT
PROMPT [STEP 1] Creating tablespaces for application data...
PROMPT

-- Create tablespace for application data
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLESPACE TOURISM_DATA
        DATAFILE ''/opt/oracle/oradata/FREEPDB1/tourism_data01.dbf'' SIZE 500M
        AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
        EXTENT MANAGEMENT LOCAL
        SEGMENT SPACE MANAGEMENT AUTO';
    DBMS_OUTPUT.PUT_LINE('Tablespace TOURISM_DATA created successfully');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1543 THEN
            DBMS_OUTPUT.PUT_LINE('Tablespace TOURISM_DATA already exists - skipping');
        ELSE
            RAISE;
        END IF;
END;
/

-- Create tablespace for indexes
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLESPACE TOURISM_INDEX
        DATAFILE ''/opt/oracle/oradata/FREEPDB1/tourism_index01.dbf'' SIZE 200M
        AUTOEXTEND ON NEXT 25M MAXSIZE UNLIMITED
        EXTENT MANAGEMENT LOCAL
        SEGMENT SPACE MANAGEMENT AUTO';
    DBMS_OUTPUT.PUT_LINE('Tablespace TOURISM_INDEX created successfully');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1543 THEN
            DBMS_OUTPUT.PUT_LINE('Tablespace TOURISM_INDEX already exists - skipping');
        ELSE
            RAISE;
        END IF;
END;
/

-- Create tablespace for temporary data
BEGIN
    EXECUTE IMMEDIATE 'CREATE TEMPORARY TABLESPACE TOURISM_TEMP
        TEMPFILE ''/opt/oracle/oradata/FREEPDB1/tourism_temp01.dbf'' SIZE 200M
        AUTOEXTEND ON NEXT 25M MAXSIZE UNLIMITED
        EXTENT MANAGEMENT LOCAL
        UNIFORM SIZE 1M';
    DBMS_OUTPUT.PUT_LINE('Temporary tablespace TOURISM_TEMP created successfully');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1543 THEN
            DBMS_OUTPUT.PUT_LINE('Temporary tablespace TOURISM_TEMP already exists - skipping');
        ELSE
            RAISE;
        END IF;
END;
/

-- ============================================================================
-- PART 2: CREATE APPLICATION USER (TOURISM_ADMIN)
-- ============================================================================

PROMPT
PROMPT [STEP 2] Creating TOURISM_ADMIN user...
PROMPT

-- Drop user if exists (development only - be careful!)
BEGIN
    EXECUTE IMMEDIATE 'DROP USER TOURISM_ADMIN CASCADE';
    DBMS_OUTPUT.PUT_LINE('Former TOURISM_ADMIN user dropped');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1918 THEN
            DBMS_OUTPUT.PUT_LINE('No existing TOURISM_ADMIN user to drop');
        ELSE
            RAISE;
        END IF;
END;
/

-- Create TOURISM_ADMIN user
CREATE USER TOURISM_ADMIN
    IDENTIFIED BY Tourism2025
    DEFAULT TABLESPACE TOURISM_DATA
    TEMPORARY TABLESPACE TOURISM_TEMP
    QUOTA UNLIMITED ON TOURISM_DATA
    QUOTA UNLIMITED ON TOURISM_INDEX
    PROFILE DEFAULT;

PROMPT User TOURISM_ADMIN created successfully

-- ============================================================================
-- PART 3: GRANT SYSTEM PRIVILEGES
-- ============================================================================

PROMPT
PROMPT [STEP 3] Granting system privileges...
PROMPT

-- Grant basic session privileges
GRANT
    CREATE SESSION,
    CREATE TABLE,
    CREATE VIEW,
    CREATE PROCEDURE,
    CREATE FUNCTION,
    CREATE PACKAGE,
    CREATE TRIGGER,
    CREATE SEQUENCE,
    CREATE INDEX,
    CREATE SYNONYM,
    ALTER SESSION,
    CREATE MATERIALIZED VIEW
TO TOURISM_ADMIN;

PROMPT Session privileges granted

-- Grant unlimited tablespace privilege
GRANT UNLIMITED TABLESPACE TO TOURISM_ADMIN;
PROMPT Unlimited tablespace privilege granted

-- Grant query rewrite privilege for materialized views
GRANT QUERY REWRITE TO TOURISM_ADMIN;
PROMPT Query rewrite privilege granted

-- Grant EXECUTE on necessary system packages
BEGIN
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_OUTPUT TO TOURISM_ADMIN';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_UTILITY TO TOURISM_ADMIN';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_LOCK TO TOURISM_ADMIN';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_SQL TO TOURISM_ADMIN';
    DBMS_OUTPUT.PUT_LINE('System package execution privileges granted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Warning: Could not grant all system package privileges');
END;
/

-- ============================================================================
-- PART 4: CREATE DIRECTORIES FOR DATA IMPORT/EXPORT
-- ============================================================================

PROMPT
PROMPT [STEP 4] Creating directories for data operations...
PROMPT

-- Create directory for data import/export
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY TOURISM_DATA_DIR AS ''/exports''';
    DBMS_OUTPUT.PUT_LINE('Directory TOURISM_DATA_DIR created');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Directory TOURISM_DATA_DIR already exists or creation failed');
END;
/

-- Create directory for export dumps
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY TOURISM_EXPORT_DIR AS ''/exports/backups''';
    DBMS_OUTPUT.PUT_LINE('Directory TOURISM_EXPORT_DIR created');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Directory TOURISM_EXPORT_DIR already exists or creation failed');
END;
/

-- Grant read/write on directories
BEGIN
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY TOURISM_DATA_DIR TO TOURISM_ADMIN';
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY TOURISM_EXPORT_DIR TO TOURISM_ADMIN';
    DBMS_OUTPUT.PUT_LINE('Directory privileges granted to TOURISM_ADMIN');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Warning: Could not grant directory privileges');
END;
/

-- ============================================================================
-- PART 5: CREATE INITIAL SCHEMA OBJECTS
-- ============================================================================

PROMPT
PROMPT [STEP 5] Creating initial schema structure...
PROMPT

-- Connect as TOURISM_ADMIN to create objects
CONN TOURISM_ADMIN/Tourism2025

-- Create base tables for tourism data

-- REGIONS table - geographic regions
CREATE TABLE REGIONS (
    REGION_ID NUMBER PRIMARY KEY,
    REGION_NAME VARCHAR2(100) NOT NULL,
    COUNTRY VARCHAR2(100),
    CONTINENT VARCHAR2(50),
    DESCRIPTION VARCHAR2(500),
    CREATED_DATE TIMESTAMP DEFAULT SYSTIMESTAMP,
    CREATED_BY VARCHAR2(50) DEFAULT USER
)
TABLESPACE TOURISM_DATA;

COMMENT ON TABLE REGIONS IS 'Geographic regions for tourism analysis';
COMMENT ON COLUMN REGIONS.REGION_ID IS 'Unique region identifier';
COMMENT ON COLUMN REGIONS.REGION_NAME IS 'Name of the geographic region';

-- DESTINATIONS table - specific tourist destinations
CREATE TABLE DESTINATIONS (
    DESTINATION_ID NUMBER PRIMARY KEY,
    DESTINATION_NAME VARCHAR2(100) NOT NULL,
    REGION_ID NUMBER NOT NULL REFERENCES REGIONS(REGION_ID),
    LATITUDE NUMBER(10,7),
    LONGITUDE NUMBER(10,7),
    DESCRIPTION VARCHAR2(500),
    CATEGORY VARCHAR2(50),
    CREATED_DATE TIMESTAMP DEFAULT SYSTIMESTAMP,
    CREATED_BY VARCHAR2(50) DEFAULT USER
)
TABLESPACE TOURISM_DATA;

CREATE INDEX IDX_DESTINATIONS_REGION ON DESTINATIONS(REGION_ID) TABLESPACE TOURISM_INDEX;

COMMENT ON TABLE DESTINATIONS IS 'Tourist destinations within regions';
COMMENT ON COLUMN DESTINATIONS.DESTINATION_ID IS 'Unique destination identifier';

-- VISITORS table - visitor records
CREATE TABLE VISITORS (
    VISITOR_ID NUMBER PRIMARY KEY,
    VISITOR_NAME VARCHAR2(100) NOT NULL,
    COUNTRY_OF_ORIGIN VARCHAR2(100),
    AGE_GROUP VARCHAR2(20),
    VISIT_DATE DATE NOT NULL,
    DESTINATION_ID NUMBER NOT NULL REFERENCES DESTINATIONS(DESTINATION_ID),
    VISIT_DURATION NUMBER,
    ACCOMMODATION_TYPE VARCHAR2(50),
    CREATED_DATE TIMESTAMP DEFAULT SYSTIMESTAMP
)
TABLESPACE TOURISM_DATA;

CREATE INDEX IDX_VISITORS_DESTINATION ON VISITORS(DESTINATION_ID) TABLESPACE TOURISM_INDEX;
CREATE INDEX IDX_VISITORS_DATE ON VISITORS(VISIT_DATE) TABLESPACE TOURISM_INDEX;

COMMENT ON TABLE VISITORS IS 'Visitor information and statistics';

-- ATTRACTIONS table - specific attractions at destinations
CREATE TABLE ATTRACTIONS (
    ATTRACTION_ID NUMBER PRIMARY KEY,
    ATTRACTION_NAME VARCHAR2(100) NOT NULL,
    DESTINATION_ID NUMBER NOT NULL REFERENCES DESTINATIONS(DESTINATION_ID),
    ATTRACTION_TYPE VARCHAR2(50),
    OPENING_HOURS VARCHAR2(50),
    ENTRANCE_FEE NUMBER(8,2),
    RATING NUMBER(3,2),
    CREATED_DATE TIMESTAMP DEFAULT SYSTIMESTAMP
)
TABLESPACE TOURISM_DATA;

CREATE INDEX IDX_ATTRACTIONS_DESTINATION ON ATTRACTIONS(DESTINATION_ID) TABLESPACE TOURISM_INDEX;

COMMENT ON TABLE ATTRACTIONS IS 'Tourist attractions and points of interest';

-- Create sequence for ID generation
CREATE SEQUENCE SEQ_REGIONS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_DESTINATIONS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_VISITORS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_ATTRACTIONS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

PROMPT Initial schema objects created successfully

-- ============================================================================
-- PART 6: CREATE SAMPLE DATA (Optional)
-- ============================================================================

PROMPT
PROMPT [STEP 6] Inserting sample data...
PROMPT

-- Insert sample regions
INSERT INTO REGIONS (REGION_ID, REGION_NAME, COUNTRY, CONTINENT, DESCRIPTION)
VALUES (SEQ_REGIONS.NEXTVAL, 'Maramures', 'Romania', 'Europe', 'Traditional villages and wooden churches');

INSERT INTO REGIONS (REGION_ID, REGION_NAME, COUNTRY, CONTINENT, DESCRIPTION)
VALUES (SEQ_REGIONS.NEXTVAL, 'Transylvania', 'Romania', 'Europe', 'Medieval towns and Carpathian mountains');

INSERT INTO REGIONS (REGION_ID, REGION_NAME, COUNTRY, CONTINENT, DESCRIPTION)
VALUES (SEQ_REGIONS.NEXTVAL, 'Danube Delta', 'Romania', 'Europe', 'Biodiversity and wetland ecosystems');

-- Insert sample destinations
INSERT INTO DESTINATIONS (DESTINATION_ID, REGION_ID, DESTINATION_NAME, LATITUDE, LONGITUDE, CATEGORY, DESCRIPTION)
VALUES (SEQ_DESTINATIONS.NEXTVAL, 1, 'Baia Mare', 47.6619, 23.5735, 'City', 'County center in Maramures');

INSERT INTO DESTINATIONS (DESTINATION_ID, REGION_ID, DESTINATION_NAME, LATITUDE, LONGITUDE, CATEGORY, DESCRIPTION)
VALUES (SEQ_DESTINATIONS.NEXTVAL, 2, 'Brasov', 45.6428, 24.7753, 'City', 'Medieval city in Transylvania');

INSERT INTO DESTINATIONS (DESTINATION_ID, REGION_ID, DESTINATION_NAME, LATITUDE, LONGITUDE, CATEGORY, DESCRIPTION)
VALUES (SEQ_DESTINATIONS.NEXTVAL, 3, 'Tulcea', 45.1859, 28.7835, 'City', 'Gateway to Danube Delta');

COMMIT;

PROMPT Sample data inserted successfully

-- ============================================================================
-- PART 7: CREATE INITIAL VIEWS FOR ANALYTICS
-- ============================================================================

PROMPT
PROMPT [STEP 7] Creating analytical views...
PROMPT

-- View: Visitor Statistics by Region
CREATE OR REPLACE VIEW V_VISITORS_BY_REGION AS
SELECT 
    R.REGION_ID,
    R.REGION_NAME,
    COUNT(V.VISITOR_ID) AS TOTAL_VISITORS,
    COUNT(DISTINCT V.COUNTRY_OF_ORIGIN) AS DISTINCT_COUNTRIES,
    AVG(V.VISIT_DURATION) AS AVG_DURATION,
    MAX(V.VISIT_DATE) AS LAST_VISIT
FROM REGIONS R
LEFT JOIN DESTINATIONS D ON R.REGION_ID = D.REGION_ID
LEFT JOIN VISITORS V ON D.DESTINATION_ID = V.DESTINATION_ID
GROUP BY R.REGION_ID, R.REGION_NAME;

COMMENT ON TABLE V_VISITORS_BY_REGION IS 'Analytical view of visitor statistics grouped by region';

-- View: Destination Performance
CREATE OR REPLACE VIEW V_DESTINATION_PERFORMANCE AS
SELECT
    D.DESTINATION_ID,
    D.DESTINATION_NAME,
    R.REGION_NAME,
    COUNT(V.VISITOR_ID) AS VISITOR_COUNT,
    COUNT(DISTINCT A.ATTRACTION_ID) AS ATTRACTION_COUNT,
    AVG(A.RATING) AS AVG_ATTRACTION_RATING,
    SUM(A.ENTRANCE_FEE) AS TOTAL_ENTRANCE_FEES
FROM DESTINATIONS D
LEFT JOIN REGIONS R ON D.REGION_ID = R.REGION_ID
LEFT JOIN VISITORS V ON D.DESTINATION_ID = V.DESTINATION_ID
LEFT JOIN ATTRACTIONS A ON D.DESTINATION_ID = A.DESTINATION_ID
GROUP BY D.DESTINATION_ID, D.DESTINATION_NAME, R.REGION_NAME;

COMMENT ON TABLE V_DESTINATION_PERFORMANCE IS 'Performance metrics for each destination';

PROMPT Analytical views created successfully

-- ============================================================================
-- PART 8: VERIFICATION AND SUMMARY
-- ============================================================================

PROMPT
PROMPT ========================================================================
PROMPT Database Initialization Complete - Verification
PROMPT ========================================================================
PROMPT

-- Display created objects
SELECT 
    OBJECT_TYPE,
    COUNT(*) AS COUNT
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('TABLE', 'VIEW', 'SEQUENCE', 'INDEX')
GROUP BY OBJECT_TYPE;

PROMPT
PROMPT ========================================================================
PROMPT Initialization Summary
PROMPT ========================================================================
PROMPT
PROMPT User:              TOURISM_ADMIN
PROMPT Password:          Tourism2025
PROMPT Default Tablespace: TOURISM_DATA
PROMPT
PROMPT Created Objects:
PROMPT   - Tablespaces (3): TOURISM_DATA, TOURISM_INDEX, TOURISM_TEMP
PROMPT   - Application User: TOURISM_ADMIN (with full privileges)
PROMPT   - Base Tables (4): REGIONS, DESTINATIONS, VISITORS, ATTRACTIONS
PROMPT   - Sequences (4): For automatic ID generation
PROMPT   - Analytical Views (2): V_VISITORS_BY_REGION, V_DESTINATION_PERFORMANCE
PROMPT   - Directories (2): TOURISM_DATA_DIR, TOURISM_EXPORT_DIR
PROMPT
PROMPT System Ready for Development!
PROMPT

SPOOL OFF

-- ============================================================================
-- END OF INITIALIZATION SCRIPT
-- ============================================================================
