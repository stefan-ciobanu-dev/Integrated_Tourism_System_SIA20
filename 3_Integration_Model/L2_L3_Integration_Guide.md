# TEMA L2 & L3: Integration & Analytical Model
# Federation Views & OLAP Analytics

## Overview

This section contains:
- **TEMA L2**: Federated Database Integration (Federation Views)
- **TEMA L3**: Analytical OLAP Model (Analytical Views)

---

## TEMA L2: Federation Model

### Purpose
Integrate the three data sources (DS_1, DS_2, DS_3) into a unified federation layer.

### Federation Views

#### V_DS1_HOTELS (Hotels Availability)
**Source**: HOTELS_DS1  
**Purpose**: Make hotel data accessible through federation layer  
**Query**:
```sql
CREATE OR REPLACE VIEW V_DS1_HOTELS AS
SELECT 
  HOTEL_ID,
  HOTEL_NAME,
  CITY,
  COUNTRY,
  STAR_RATING,
  ROOMS_TOTAL,
  PRICE_PER_NIGHT,
  'DS_1' as SOURCE_SYSTEM,
  'Direct SQL' as ACCESS_METHOD
FROM TOURISM_ADMIN.HOTELS_DS1;
```

#### V_DS2_FLIGHTS (Active Flights)
**Source**: FLIGHTS_DS2_CACHE (from OpenSky API)  
**Purpose**: Expose real flight data through federation  
**Query**:
```sql
CREATE OR REPLACE VIEW V_DS2_FLIGHTS AS
SELECT 
  FLIGHT_ID,
  CALLSIGN,
  ORIGIN_AIRPORT,
  DESTINATION_AIRPORT,
  LATITUDE,
  LONGITUDE,
  ALTITUDE_M,
  VELOCITY_MS,
  'DS_2' as SOURCE_SYSTEM,
  'REST API (OpenSky)' as ACCESS_METHOD
FROM TOURISM_ADMIN.FLIGHTS_DS2_CACHE;
```

#### V_DS3_CURRENCIES (Exchange Rates)
**Source**: CURRENCY_DS3 (from ECB XML)  
**Purpose**: Provide currency conversion rates  
**Query**:
```sql
CREATE OR REPLACE VIEW V_DS3_CURRENCIES AS
SELECT 
  CURRENCY_CODE,
  CURRENCY_NAME,
  EUR_RATE,
  RATE_DATE,
  'DS_3' as SOURCE_SYSTEM,
  'HTTP XML (ECB)' as ACCESS_METHOD
FROM TOURISM_ADMIN.CURRENCY_DS3;
```

#### V_FEDERATION_SUMMARY (All Sources Status)
**Purpose**: Show status and record count of all federation sources  
**Query**:
```sql
CREATE OR REPLACE VIEW V_FEDERATION_SUMMARY AS
SELECT 
  'DS_1: Hotels' as SOURCE,
  COUNT(*) as RECORD_COUNT,
  'Direct SQL' as ACCESS_METHOD,
  'Online' as STATUS
FROM TOURISM_ADMIN.HOTELS_DS1
UNION ALL
SELECT 
  'DS_2: Flights',
  COUNT(*),
  'REST API Cache',
  'Online'
FROM TOURISM_ADMIN.FLIGHTS_DS2_CACHE
UNION ALL
SELECT 
  'DS_3: Currencies',
  COUNT(*),
  'HTTP XML',
  'Online'
FROM TOURISM_ADMIN.CURRENCY_DS3;
```

---

## TEMA L3: Analytical OLAP Model

### Fact Tables

#### FACT_BOOKINGS
**Purpose**: Central fact table for booking analytics  
**Dimensions**: Accommodation, Location, Date, Currency  
**Measures**: Booking count, Revenue (EUR)

#### FACT_ACCOMMODATION
**Purpose**: Hotel occupancy and performance metrics  
**Dimensions**: Hotel, Date, Location  
**Measures**: Rooms booked, Average occupancy, Revenue

### Dimension Tables

#### DIM_HOTEL (Slowly Changing Dimension)
**Fields**: Hotel ID, Name, City, Country, Star Rating, Category

#### DIM_CURRENCY
**Fields**: Currency Code, Name, EUR Rate, Valid From, Valid To

#### DIM_LOCATION (Geographic Hierarchy)
**Fields**: Location ID, City, Region, Country, Continent

#### DIM_DATE (Time Dimension)
**Fields**: Date ID, Calendar Date, Day, Month, Quarter, Year, Season

### OLAP Analytics Views

#### V_ANALYTICS_REVENUE_ROLLUP
**Type**: Aggregation with ROLLUP
**Purpose**: Revenue by hotel, city, country hierarchy
```sql
SELECT 
  HOTEL,
  CITY,
  COUNTRY,
  SUM(REVENUE) as TOTAL_REVENUE,
  COUNT(*) as BOOKING_COUNT
FROM ...
GROUP BY ROLLUP (COUNTRY, CITY, HOTEL)
ORDER BY COUNTRY, CITY, HOTEL;
```

#### V_ANALYTICS_LOCATION_CUBE  
**Type**: Multi-dimensional CUBE
**Purpose**: Cross-dimensional analysis (Hotel × City × Currency)
```sql
SELECT 
  HOTEL,
  CITY,
  CURRENCY,
  SUM(AMOUNT) as TOTAL,
  COUNT(*) as TRANSACTIONS
GROUP BY CUBE (HOTEL, CITY, CURRENCY)
```

#### V_ANALYTICS_TOP_PERFORMERS
**Type**: Ranking with ROW_NUMBER()
**Purpose**: Top 5 hotels by bookings and revenue
```sql
SELECT 
  HOTEL_NAME,
  STAR_RATING,
  BOOKINGS,
  TOTAL_REVENUE,
  ROW_NUMBER() OVER (ORDER BY TOTAL_REVENUE DESC) as RANK
FROM ...
WHERE ROWNUM <= 5;
```

#### V_ANALYTICS_TEMPORAL_TREND
**Type**: Time series analysis
**Purpose**: Revenue trend by date
```sql
SELECT 
  CHECK_IN_DATE,
  SUM(TOTAL_AMOUNT_EUR) as DAILY_REVENUE,
  SUM(SUM(TOTAL_AMOUNT_EUR)) OVER (ORDER BY CHECK_IN_DATE) as CUMULATIVE_REVENUE
FROM ...
GROUP BY CHECK_IN_DATE;
```

#### V_ANALYTICS_GEOGRAPHIC_HEATMAP
**Type**: Geographic aggregation
**Purpose**: Revenue and booking density by location
```sql
SELECT 
  CITY,
  COUNTRY,
  SUM(REVENUE) as TOTAL_REVENUE,
  COUNT(BOOKING_ID) as BOOKING_COUNT,
  LATITUDE,
  LONGITUDE
FROM ...
GROUP BY CITY, COUNTRY, LATITUDE, LONGITUDE;
```

---

## Implementation Files

- [TEMA_L2_FEDERATED_ACCESS.sql](./TEMA_L2_FEDERATED_ACCESS.sql) - All federation views
- [TEMA_L3_OLAP_VIEWS.sql](./TEMA_L3_OLAP_VIEWS.sql) - All OLAP analytical views
- [Integration_Model_Diagram.md](./Integration_Model_Diagram.md) - Visual architecture

---

## Deployment

Both L2 and L3 are implemented in Oracle database:

1. Federation layer (L2) makes 3 sources accessible
2. Analytical layer (L3) aggregates for reporting
3. REST API (P3) exposes views via HTTP endpoints
4. Dashboard (P3) visualizes OLAP results

---

**Document Date**: April 7, 2026  
**Status**: ✅ All federation and OLAP views implemented and tested
