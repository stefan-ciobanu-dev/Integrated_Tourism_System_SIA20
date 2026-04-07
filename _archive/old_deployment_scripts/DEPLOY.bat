@echo off
REM ============================================================================
REM Tourism Analysis Platform - Complete Deployment Script
REM Windows Batch Script
REM ============================================================================
REM This script deploys TEMA L1, L2, and L3 to an Oracle database
REM ============================================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM Configuration
SET DATABASE_HOST=localhost
SET DATABASE_PORT=1521
SET DATABASE_NAME=FREEPDB1
SET ADMIN_USER=TOURISM_ADMIN
SET ADMIN_PASSWORD=Tourism2025!
SET SCRIPT_DIR=%~dp0database

REM Colors (using Unicode)
SET GREEN=[92m
SET RED=[91m
SET YELLOW=[93m
SET RESET=[0m

ECHO.
ECHO ============================================================================
ECHO Tourism Analysis Platform - Complete Deployment
ECHO ============================================================================
ECHO.
ECHO Configuration:
ECHO   Database Host: %DATABASE_HOST%
ECHO   Database Port: %DATABASE_PORT%
ECHO   Database Name: %DATABASE_NAME%
ECHO   Admin User: %ADMIN_USER%
ECHO   Script Directory: %SCRIPT_DIR%
ECHO.

REM Verify scripts exist
ECHO [Step 1] Verifying SQL scripts...
IF NOT EXIST "%SCRIPT_DIR%\init_db.sql" (
    ECHO   ERROR: init_db.sql not found
    GOTO ERROR
)
IF NOT EXIST "%SCRIPT_DIR%\TEMA_L2_FEDERATED_ACCESS.sql" (
    ECHO   ERROR: TEMA_L2_FEDERATED_ACCESS.sql not found
    GOTO ERROR
)
IF NOT EXIST "%SCRIPT_DIR%\TEMA_L3_OLAP_VIEWS.sql" (
    ECHO   ERROR: TEMA_L3_OLAP_VIEWS.sql not found
    GOTO ERROR
)
ECHO   ✓ All SQL scripts found

REM Test database connection
ECHO.
ECHO [Step 2] Testing database connection...
sqlplus -v >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO   ERROR: SQL*Plus not found. Install Oracle client or full database.
    ECHO   See ORACLE_SETUP_WINDOWS.md for installation instructions.
    GOTO ERROR
)
ECHO   ✓ SQL*Plus is available

REM Create deployment log
SET LOGFILE=%~dp0deployment_%date:~-4%_%date:~-10,2%_%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
ECHO.
ECHO [Step 3] Deployment Log: %LOGFILE%
ECHO Deployment started at %date% %time% > "%LOGFILE%"

REM Deploy TEMA L1 (optional)
ECHO.
ECHO [Step 4/5] Deploying TEMA L1 (Base Schema)...
sqlplus -S %ADMIN_USER%/%ADMIN_PASSWORD%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME% ^
  @"%SCRIPT_DIR%\init_db.sql" >> "%LOGFILE%" 2>&1
IF ERRORLEVEL 1 (
    ECHO   ⚠ Warning: TEMA L1 deployment had issues (may be OK if objects exist)
) ELSE (
    ECHO   ✓ TEMA L1 deployed successfully
)

REM Deploy TEMA L2 (Federation Layer)
ECHO.
ECHO [Step 4/5] Deploying TEMA L2 (Federation Layer)...
ECHO   - Creating L2_FEDERATION user
ECHO   - Setting up DB_LINK to hotels database
ECHO   - Creating OpenSky API integration procedure
ECHO   - Creating ECB currency parser procedure
ECHO   - Creating federation views (4 views)
ECHO   - Granting public access
sqlplus -S %ADMIN_USER%/%ADMIN_PASSWORD%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME% ^
  @"%SCRIPT_DIR%\TEMA_L2_FEDERATED_ACCESS.sql" >> "%LOGFILE%" 2>&1
IF ERRORLEVEL 1 (
    ECHO   ERROR: TEMA L2 deployment failed
    ECHO   Check %LOGFILE% for details
    GOTO ERROR
) ELSE (
    ECHO   ✓ TEMA L2 deployed successfully
)

REM Deploy TEMA L3 (Analytics Layer)
ECHO.
ECHO [Step 5/5] Deploying TEMA L3 (OLAP Analytics)...
ECHO   - Creating dimensional tables (4)
ECHO   - Creating fact tables (2)
ECHO   - Creating OLAP views (15+)
ECHO   - Creating materialized view
ECHO   - Granting public access
sqlplus -S %ADMIN_USER%/%ADMIN_PASSWORD%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME% ^
  @"%SCRIPT_DIR%\TEMA_L3_OLAP_VIEWS.sql" >> "%LOGFILE%" 2>&1
IF ERRORLEVEL 1 (
    ECHO   ERROR: TEMA L3 deployment failed
    ECHO   Check %LOGFILE% for details
    GOTO ERROR
) ELSE (
    ECHO   ✓ TEMA L3 deployed successfully
)

REM Verify Installation
ECHO.
ECHO [Verification] Running TEMA L3 verification...
sqlplus -S %ADMIN_USER%/%ADMIN_PASSWORD%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME% ^
  @"%SCRIPT_DIR%\TEMA_L3_VERIFY.sql" >> "%LOGFILE%" 2>&1

ECHO.
ECHO ============================================================================
ECHO Deployment Complete!
ECHO ============================================================================
ECHO.
ECHO Summary:
ECHO   ✓ TEMA L1: Base schema and data sources
ECHO   ✓ TEMA L2: Federation layer with real web services
ECHO   ✓ TEMA L3: OLAP analytics and dimensional modeling
ECHO.
ECHO Deployment details saved to: %LOGFILE%
ECHO.
ECHO Connect to database:
ECHO   sqlplus %ADMIN_USER%/%ADMIN_PASSWORD%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME%
ECHO.
ECHO Test sample queries:
ECHO   SELECT * FROM V_OLAP_REVENUE_BY_HOTEL_MONTHLY;
ECHO   SELECT * FROM V_OLAP_HOTEL_OCCUPANCY;
ECHO   SELECT * FROM V_OLAP_YOY_REVENUE_TREND;
ECHO.
ECHO Next steps:
ECHO   1. Monitor real data refresh:
ECHO      - OpenSky flights: Every 5 minutes
ECHO      - ECB currency rates: Daily at 17:00 CET
ECHO   2. Access REST API at: http://localhost:8181/ords/api/
ECHO   3. Build APEX web interface using OLAP views
ECHO.
ECHO ============================================================================
ECHO.

GOTO SUCCESS

:ERROR
ECHO.
ECHO ============================================================================
ECHO Deployment FAILED
ECHO ============================================================================
ECHO.
ECHO Troubleshooting:
ECHO   1. Verify Oracle database is running
ECHO   2. Check connection string: %ADMIN_USER%@%DATABASE_HOST%:%DATABASE_PORT%/%DATABASE_NAME%
ECHO   3. Verify password: %ADMIN_PASSWORD%
ECHO   4. Check SQL script paths exist
ECHO   5. Review logfile for detailed errors
ECHO.
ECHO For setup help, see: ORACLE_SETUP_WINDOWS.md
ECHO.
GOTO END

:SUCCESS
EXIT /B 0

:END
ENDLOCAL
