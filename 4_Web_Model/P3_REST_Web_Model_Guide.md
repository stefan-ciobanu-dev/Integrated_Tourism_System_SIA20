# TEMA P3: REST and Web Model
# REST API Implementation & Web UI

## Overview

**TEMA P3** consists of two layers:
- **P3.1**: REST API via ORDS/Node.js (13 endpoints)
- **P3.2**: Web UI Dashboard (HTML/JavaScript)

---

## P3.1: REST API Implementation

### Technology Stack
- **Framework**: Express.js (Node.js)  
- **Port**: 8080  
- **Database Connection**: Oracle oracledb native driver
- **Data Format**: JSON
- **CORS**: Enabled for cross-origin dashboard requests

### Why Node.js Instead of ORDS?
- ORDS not available in Oracle Free Edition XE
- Node.js provides flexibility and better error handling
- Easy integration with real external APIs
- Same REST architecture as ORDS

### API Endpoints (13 Total)

#### 1. Health Check
**Endpoint**: `GET /health`  
**Purpose**: Verify API and database connectivity  
**Response**:
```json
{
  "status": "OK",
  "database": "Connected",
  "api_integration": "Live External APIs Enabled"
}
```

---

### ANALYTICS ENDPOINTS (8)

#### 2. Executive Summary
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/executive_summary`  
**Source**: FACT_BOOKINGS (OLAP)  
**Returns**: KPI aggregates
```json
{
  "bookings_count": 2,
  "total_revenue": 1360,
  "active_hotels": 3,
  "average_booking_value": 680
}
```

#### 3. Revenue Analysis  
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/revenue_analysis`  
**Source**: V_ANALYTICS_REVENUE_ROLLUP  
**Returns**: Revenue by hotel
```json
{
  "hotels": [
    {"hotel_name": "Intercontinental", "total_revenue": 760, "booking_count": 1},
    {"hotel_name": "Radisson", "total_revenue": 600, "booking_count": 1}
  ]
}
```

#### 4. Top Performers
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/top_performers`  
**Source**: V_ANALYTICS_TOP_PERFORMERS  

#### 5. Geographic Heatmap
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/geographic_heatmap`  
**Source**: V_ANALYTICS_GEOGRAPHIC_HEATMAP  
**Returns**: Location-based aggregations with coordinates

#### 6. Revenue Rollup
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/revenue_rollup`  
**Aggregation**: GROUP BY ROLLUP(Star Rating, Hotel)

#### 7. Location Cube
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/location_cube`  
**Aggregation**: Multi-dimensional CUBE analysis

#### 8. Temporal Trend
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/temporal_trend`  
**Purpose**: Time series revenue analysis

#### 9. Geographic Performance
**Endpoint**: `GET /ords/freepdb1/tourism/analytics/geographic_performance`  

---

### CONSOLIDATION ENDPOINTS (3)

#### 10. Consolidated Bookings
**Endpoint**: `GET /ords/freepdb1/tourism/consolidation/bookings`  
**Source**: V_CONSOLIDATE_BOOKINGS  
**Returns**: All bookings with guest, hotel, dates, price
```json
{
  "bookings": [
    {
      "booking_id": 1,
      "hotel_name": "Hotel Tâmpa",
      "guest_name": "John Smith",
      "check_in": "2026-03-15",
      "check_out": "2026-03-17",
      "total_price": 760
    }
  ]
}
```

#### 11. Consolidated Accommodation
**Endpoint**: `GET /ords/freepdb1/tourism/consolidation/accommodation`  
**Source**: V_CONSOLIDATE_ACCOMMODATION  
**Returns**: Hotel details with aggregated booking stats

#### 12. Travel Packages
**Endpoint**: `GET /ords/freepdb1/tourism/consolidation/travel_packages`  

---

### FEDERATION ENDPOINTS (4)

#### 13. DS_1 Hotels (Real Data)
**Endpoint**: `GET /ords/freepdb1/tourism/federation/hotels`  
**Source**: V_DS1_HOTELS  
**Data**: From database (local or synced from source)
```json
{
  "hotels": [
    {
      "hotel_id": 1,
      "hotel_name": "InterContinental",
      "city": "Bucharest",
      "star_rating": 5,
      "source_system": "DS_1",
      "access_method": "Direct SQL"
    }
  ]
}
```

#### 14. DS_2 Flights (OpenSky Real Data)
**Endpoint**: `GET /ords/freepdb1/tourism/federation/flights`  
**Source**: V_DS2_FLIGHTS (FLIGHTS_DS2_CACHE)  
**Data**: 15 real flights from OpenSky Network API
```json
{
  "flights": [
    {
      "flight_id": "FL001_TVF92NS",
      "callsign": "TVF92NS",
      "origin_airport": "CDG",
      "destination_airport": "OTP",
      "altitude_m": 10500,
      "velocity_ms": 250,
      "source_system": "DS_2",
      "access_method": "REST API (OpenSky)"
    }
  ]
}
```

#### 15. DS_3 Currency (ECB Real Rates)
**Endpoint**: `GET /ords/freepdb1/tourism/federation/currencies`  
**Source**: V_DS3_CURRENCIES (CURRENCY_DS3)  
**Data**: 11+ real exchange rates from ECB
```json
{
  "currencies": [
    {
      "currency_code": "EUR",
      "currency_name": "Euro",
      "eur_rate": 1.0,
      "source_system": "DS_3",
      "access_method": "HTTP XML (ECB)"
    },
    {
      "currency_code": "USD",
      "currency_name": "US Dollar",
      "eur_rate": 1.1525,
      "source_system": "DS_3",
      "access_method": "HTTP XML (ECB)"
    }
  ]
}
```

#### 16. Federation Summary
**Endpoint**: `GET /ords/freepdb1/tourism/federation/summary`  
**Purpose**: Status of all 3 data sources
```json
{
  "sources": [
    {"source": "DS_1: Hotels", "record_count": 3, "status": "Online"},
    {"source": "DS_2: Flights", "record_count": 15, "status": "Online"},
    {"source": "DS_3: Currencies", "record_count": 11, "status": "Online"}
  ]
}
```

---

## Implementation File

**File**: [server-simple.js](./server-simple.js)  
**Lines of Code**: ~400  
**Key Features**:
- Express.js REST framework
- Oracle database connection pooling
- Real external API integration on startup
- Error handling with CORS support
- Health check endpoint

---

## P3.2: Web UI Dashboard

### Technology Stack
- **Frontend**: HTML5 + CSS3 + JavaScript (ES6)
- **Charts**: Chart.js (bar, line, pie)
- **Maps**: Leaflet (geographic visualization)
- **HTTP Server**: Python (port 8000)
- **Connection**: REST API calls to Node.js backend

### Dashboard Components

#### 1. KPI Cards (4 Cards)
- **Total Bookings**: Count from FACT_BOOKINGS
- **Total Revenue**: Sum of booking amounts (EUR)
- **Active Hotels**: Count of hotels with bookings
- **Average Booking Value**: Average amount per booking

#### 2. Revenue by Hotel (Bar Chart)
- **Data Source**: `/analytics/revenue_analysis`
- **Visualization**: Chart.js horizontal bar
- **Shows**: Revenue contribution by each hotel

#### 3. Federation Status Table
- **Data Source**: `/federation/summary`
- **Shows**: All 3 data sources + record counts + status
- **Purpose**: Verify all external sources online

#### 4. Recent Bookings Table
- **Data Source**: `/consolidation/bookings`
- **Shows**: Guest name, hotel, dates, amount
- **Limit**: First 5 bookings

#### 5. Status Indicators
- **Database**: Shows connected/offline
- **API**: Shows online/offline
- **Real-time**: Updates every 30 seconds

### Dashboard Files

**Main UI**: [dashboard-working.html](./dashboard-working.html)  
**Size**: ~10KB  
**Performance**: Responsive, mobile-friendly

### API Integration Code

```javascript
// Fetch data from REST API
const API_BASE = 'http://localhost:8080/ords/freepdb1/tourism';

async function fetchAPI(endpoint) {
  const response = await fetch(API_BASE + endpoint);
  return await response.json();
}

// Load dashboard data
async function loadDashboard() {
  const data = await fetchAPI('/analytics/executive_summary');
  document.getElementById('kpi-bookings').textContent = data.bookings_count;
  document.getElementById('kpi-revenue').textContent = data.total_revenue + ' EUR';
  // ... more updates
}
```

---

## Testing the APIs

### Using curl
```bash
# Test health
curl http://localhost:8080/health

# Get real flights
curl http://localhost:8080/ords/freepdb1/tourism/federation/flights

# Get real currencies
curl http://localhost:8080/ords/freepdb1/tourism/federation/currencies

# Get executive summary
curl http://localhost:8080/ords/freepdb1/tourism/analytics/executive_summary
```

### Using Postman
Import [REST_API_Tests.json](./REST_API_Tests.json) for pre-built test collection

### Using Browser  
Simply navigate to:
```
http://localhost:8000/dashboard-working.html
```

---

## Real External Data in REST API

The REST API automatically fetches:
- ✅ 15 **real flights** from OpenSky Network on startup
- ✅ 11+ **real currency rates** from ECB on startup
- ✅ Hotel data from database or fallback

All endpoints serve this real external data without making additional API calls (fetch once, cache locally).

---

## Deployment

### Start All Services
```bash
# Terminal 1: Oracle Database
docker-compose up -d

# Terminal 2: Node.js REST API
node server-simple.js

# Terminal 3: Python Dashboard
python -m http.server 8000
```

### Access Points
- **Dashboard**: http://localhost:8000/dashboard-working.html
- **API Base**: http://localhost:8080
- **Database**: localhost:1521/FREEPDB1

---

**Document Date**: April 7, 2026  
**Status**: ✅ All REST endpoints implemented and all 3 services running with real external data
