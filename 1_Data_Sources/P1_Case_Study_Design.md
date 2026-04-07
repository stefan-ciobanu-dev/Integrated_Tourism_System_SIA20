# TEMA L1: Proiectarea Studiului de Caz
# Tourism Analytics Platform - Case Study Design

## Executive Summary

This project integrates three external data sources representing different tourism business domains:
- **DS_1**: Hotel Accommodation Management System
- **DS_2**: Flight Operations & Aircraft Tracking  
- **DS_3**: Foreign Exchange Currency Rates

---

## Data Sources Overview

| DS # | Source | Domain | Format | Type | API |
|------|--------|--------|--------|------|-----|
| **DS_1** | Hotels Management | Accommodation | SQL | Relational | OpenStreetMap Overpass API |
| **DS_2** | Flight Operations | Transportation | JSON | REST API | OpenSky Network |
| **DS_3** | Exchange Rates | Commerce | XML | HTTP Feed | European Central Bank (ECB) |

---

## DS_1: Hotel Accommodation System

### Purpose
Represents a hotel chain management system with property information, room inventory, and booking data.

### Data Model
- **Type**: Relational SQL
- **Access**: Direct Oracle tables + REST API fallback
- **Primary Source**: OpenStreetMap Overpass API
- **Query Zone**: Romania (Bucharest area, 44-47°N, 24-27°E)

### Tables & Fields
```
HOTELS_DS1:
├── HOTEL_ID (PK)
├── HOTEL_NAME
├── CITY
├── COUNTRY  
├── STAR_RATING (1-5)
├── ROOMS_TOTAL
├── PRICE_PER_NIGHT (EUR)
├── POOL (Y/N)
└── WIFI (Y/N)

ROOM_TYPES_DS1:
├── ROOM_TYPE_ID (PK)
├── HOTEL_ID (FK)
├── ROOM_TYPE_NAME
├── CAPACITY
├── BASE_PRICE
├── TAX_RATE
└── AVAILABILITY

BOOKINGS_DS1:
├── BOOKING_ID (PK)
├── HOTEL_ID (FK)
├── GUEST_NAME
├── CHECK_IN_DATE
├── CHECK_OUT_DATE
└── TOTAL_AMOUNT
```

---

## DS_2: Flight Operations System

### Purpose
Live aircraft tracking and flight operations data.

### Data Model
- **Type**: REST API (JSON)
- **Access**: Real-time via OpenSky Network API
- **Primary Source**: OpenSky Network (https://opensky-network.org/api/states/all)
- **Query Zone**: Romania airspace (44-47°N, 24-27°E)

### Tables & Fields
```
FLIGHTS_DS2_CACHE:
├── FLIGHT_ID (PK)
├── ICAO24 
├── CALLSIGN
├── ORIGIN_COUNTRY
├── ORIGIN_AIRPORT
├── DESTINATION_AIRPORT
├── LATITUDE
├── LONGITUDE
├── ALTITUDE_M (meters)
├── VELOCITY_MS (m/s)
└── CAPTURE_TIME
```

---

## DS_3: Currency Exchange Rates

### Purpose
Daily official EUR foreign exchange conversion rates.

### Data Model
- **Type**: XML HTTP Feed
- **Access**: ECB Official XML feed
- **Primary Source**: European Central Bank (https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml)
- **Update Frequency**: Daily

### Tables & Fields
```
CURRENCY_DS3:
├── CURRENCY_CODE (PK) - EUR, USD, GBP, etc.
├── CURRENCY_NAME
├── EUR_RATE (conversion rate)
├── RATE_DATE
├── SOURCE (ECB)
└── LAST_UPDATE
```

---

## External API Integration

### OpenSky Network (DS_2)
**API Endpoint**: `https://opensky-network.org/api/states/all?lamin=44&lamax=47&lomin=24&lomax=27`

**Response Format**: JSON  
**Rate Limit**: 400 requests/hour (unlimited for academic projects)  
**Data**: Live flight positions, callsigns, altitudes (15+ flights cached)

### European Central Bank (DS_3)
**Feed URL**: `https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml`

**Response Format**: XML  
**Update**: Daily at 16:00 CET  
**Data**: Official EUR reference rates (11+ currencies cached)

### OpenStreetMap Overpass (DS_1 - Optional)
**API Endpoint**: `https://overpass-api.de/api/interpreter`

**Query**: Hotel POIs in Bucharest region  
**Response Format**: JSON/XML  
**Status**: Fallback implementation available

---

## Data Integration Strategy

1. **Initial Load**: Fetch real data from external APIs on system startup
2. **Local Caching**: Store in Oracle tables for federation layer access
3. **Persistence**: Data remains static for semester (no live refresh)
4. **Access**: All TEMA L2/L3/P3 layers query the local cached tables

---

## Documentation References

See additional files:
- [DS1_Hotels_Definition.md](./DS1_Hotels_Definition.md)
- [DS2_Flights_Definition.md](./DS2_Flights_Definition.md)
- [DS3_Currency_Definition.md](./DS3_Currency_Definition.md)
- [External_APIs_Configuration.md](./External_APIs_Configuration.md)

---

**Document Date**: April 7, 2026  
**Project**: Tourism Analysis Platform (TEMA L1-L3, P3)  
**Status**: ✅ Real External APIs Integrated
