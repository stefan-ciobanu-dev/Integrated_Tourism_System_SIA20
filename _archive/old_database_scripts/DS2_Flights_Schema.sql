-- ============================================================================
-- DS2: Flight Operations System - OpenSky Network
-- Data Model Definition
-- ============================================================================

CREATE TABLE IF NOT EXISTS TOURISM_ADMIN.FLIGHTS_DS2_CACHE (
  FLIGHT_ID VARCHAR2(50) PRIMARY KEY,
  ICAO24 VARCHAR2(6),
  CALLSIGN VARCHAR2(20),
  ORIGIN_COUNTRY VARCHAR2(50),
  ORIGIN_AIRPORT VARCHAR2(10),
  DESTINATION_AIRPORT VARCHAR2(10),
  LATITUDE NUMBER(10,6),
  LONGITUDE NUMBER(11,6),
  ALTITUDE_M NUMBER(10,2),
  VELOCITY_MS NUMBER(10,2),
  CAPTURE_TIME TIMESTAMP DEFAULT SYSDATE
) TABLESPACE USERS;

-- Indexes for performance
CREATE INDEX IDX_FLIGHTS_CALLSIGN ON TOURISM_ADMIN.FLIGHTS_DS2_CACHE(CALLSIGN);
CREATE INDEX IDX_FLIGHTS_ORIGIN ON TOURISM_ADMIN.FLIGHTS_DS2_CACHE(ORIGIN_COUNTRY);
CREATE INDEX IDX_FLIGHTS_ALTITUDE ON TOURISM_ADMIN.FLIGHTS_DS2_CACHE(ALTITUDE_M);

-- Data loaded from OpenSky Network API at startup
-- Sample insertion (in production: real data from https://opensky-network.org/api/states/all)
BEGIN
  DELETE FROM TOURISM_ADMIN.FLIGHTS_DS2_CACHE;
  
  -- Real flights will be inserted by Node.js server during initialization
  -- Following data structure from OpenSky API response:
  -- [ICAO24, callsign, origin_country, time_position, last_contact, 
  --  latitude, longitude, baro_altitude, on_ground, velocity, true_track, 
  --  vertical_rate, sensors, geo_altitude, squawk, spi, position_source]
  
  -- Fallback sample data (replaced by real data on startup)
  INSERT INTO TOURISM_ADMIN.FLIGHTS_DS2_CACHE 
    (FLIGHT_ID, ICAO24, CALLSIGN, ORIGIN_COUNTRY, ORIGIN_AIRPORT, DESTINATION_AIRPORT, 
     LATITUDE, LONGITUDE, ALTITUDE_M, VELOCITY_MS)
  VALUES ('FL001_UNKOWN1', 'UNKNOWN1', 'SAMPLE01', 'Romania', 'OTP', 'VIE', 44.4, 26.1, 10000, 450);
  
  INSERT INTO TOURISM_ADMIN.FLIGHTS_DS2_CACHE 
    (FLIGHT_ID, ICAO24, CALLSIGN, ORIGIN_COUNTRY, ORIGIN_AIRPORT, DESTINATION_AIRPORT, 
     LATITUDE, LONGITUDE, ALTITUDE_M, VELOCITY_MS)
  VALUES ('FL002_UNKNOWN2', 'UNKNOWN2', 'SAMPLE02', 'Germany', 'VIE', 'BUH', 45.0, 25.0, 8500, 480);
  
  INSERT INTO TOURISM_ADMIN.FLIGHTS_DS2_CACHE 
    (FLIGHT_ID, ICAO24, CALLSIGN, ORIGIN_COUNTRY, ORIGIN_AIRPORT, DESTINATION_AIRPORT, 
     LATITUDE, LONGITUDE, ALTITUDE_M, VELOCITY_MS)
  VALUES ('FL003_UNKNOWN3', 'UNKNOWN3', 'SAMPLE03', 'Hungary', 'BUD', 'LYS', 46.8, 24.5, 12000, 420);
  
  COMMIT;
END;
/

PROMPT DS_2 Flights table created
PROMPT Note: Real flight data from OpenSky Network (https://opensky-network.org/api/states/all)
PROMPT       will populate this table on server startup via Node.js integration
