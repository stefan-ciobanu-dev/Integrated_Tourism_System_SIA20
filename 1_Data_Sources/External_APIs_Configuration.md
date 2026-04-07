# External APIs Configuration
# Tourism Analytics Platform - Real Data Source Integration

## API Endpoints & Documentation

### 1. OpenSky Network - Live Aircraft Tracking
**Purpose**: DS_2 - Flight Operations & Transportation Data  
**Endpoint**: `https://opensky-network.org/api/states/all`

#### Query Parameters
```
lamin=44          # Latitude minimum (south)
lamax=47          # Latitude maximum (north)  
lomin=24          # Longitude minimum (west)
lomax=27          # Longitude maximum (east)
```

**Full URL Used**:
```
https://opensky-network.org/api/states/all?lamin=44&lamax=47&lomin=24&lomax=27
```

#### Response Format
```json
{
  "time": 1712499123,
  "states": [
    [
      "ICAO24",        // Aircraft ICAO code
      "CALLSIGN",      // Flight callsign
      "ORIGIN",        // Origin country
      "TIME",          // Last position timestamp
      "LAT",           // Latitude
      "LON",           // Longitude
      "BAROALT",       // Barometric altitude
      "ONGROUND",      // On ground flag
      "VELOCITY",      // Velocity m/s
      ...
    ]
  ]
}
```

#### Implementation
- **Access Method**: REST API call on server startup
- **Update Frequency**: Static (loaded once per deployment)
- **Records Cached**: 15 real flights from OpenSky
- **Column Mapping**: See [2_Data_Models/DS2_Flights_Schema.sql](../2_Data_Models/DS2_Flights_Schema.sql)

#### Documentation
- Website: https://opensky-network.org
- API Docs: https://opensky-network.org/api/current/

---

### 2. European Central Bank - Daily EUR Exchange Rates
**Purpose**: DS_3 - Foreign Exchange & Currency Rates

**Feed URL**: `https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml`

#### Response Format
```xml
<?xml version="1.0" encoding="UTF-8"?>
<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
  <gesmes:subject>Reference rates</gesmes:subject>
  <gesmes:Sender>
    <gesmes:name>European Central Bank</gesmes:name>
  </gesmes:Sender>
  <Cube>
    <Cube time="2026-04-07">
      <Cube currency="USD" rate="1.1525"/>
      <Cube currency="JPY" rate="183.94"/>
      <Cube currency="GBP" rate="0.8560"/>
      ...
    </Cube>
  </Cube>
</gesmes:Envelope>
```

#### Implementation
- **Access Method**: HTTP GET + XML parsing
- **Update Frequency**: Daily at 16:00 CET
- **Records Cached**: 11+ official currencies from ECB
- **Column Mapping**: See [2_Data_Models/DS3_Currency_Schema.sql](../2_Data_Models/DS3_Currency_Schema.sql)

#### Documentation
- Website: https://www.ecb.europa.eu/
- Reference Rates: https://www.ecb.europa.eu/stats/eurofxref/

---

### 3. OpenStreetMap Overpass - Hotel Points of Interest (Optional)
**Purpose**: DS_1 - Hotel Accommodation Data

**Endpoint**: `https://overpass-api.de/api/interpreter`

#### Query Example
```
[bbox:44.2,25.5,44.6,26.3];
(node["tourism"="hotel"];way["tourism"="hotel"];relation["tourism"="hotel"];);
out center;
```

#### Response Format
```json
{
  "elements": [
    {
      "type": "node",
      "id": 12345,
      "lat": 44.4, 
      "lon": 26.1,
      "tags": {
        "name": "Hotel Name",
        "tourism": "hotel",
        "addr:city": "Bucharest",
        "stars": "3"
      }
    }
  ]
}
```

#### Implementation
- **Access Method**: REST API with Overpass Query Language (QL)
- **Fallback**: Simulated data if API fails
- **Status**: Available but not primary source
- **Documentation**: https://wiki.openstreetmap.org/wiki/Overpass_API

---

## Integration in Node.js Backend

### Startup Sequence
When `server-simple.js` starts:

```javascript
// 1. Fetch real flights from OpenSky
fetchRealFlights()   
→ Call: https://opensky-network.org/api/states/all?...
→ Parse JSON response
→ Insert 15 flights into FLIGHTS_DS2_CACHE

// 2. Fetch real currency rates from ECB
fetchRealCurrencies()
→ Call: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
→ Parse XML response
→ Insert 11 currencies into CURRENCY_DS3

// 3. Hotel data (optional)
fetchRealHotels()     
→ Call: https://overpass-api.de/api/interpreter
→ Parse hotel POI data
→ Insert into HOTELS_DS1 or use fallback
```

### Error Handling
- Each fetch has try-catch with graceful fallback
- If API fails: "Using fallback data..."
- Server continues even if external APIs unavailable
- All 3 servers (Oracle, Node.js, Dashboard) remain operational

### Timeouts
- OpenSky: 10 second timeout
- ECB: 10 second timeout
- Fallback: Automatically engages if no response

---

## Database Tables Created

| Table | Source | Records | Update |
|-------|--------|---------|--------|
| FLIGHTS_DS2_CACHE | OpenSky | 15 real | Startup |
| CURRENCY_DS3 | ECB | 11 official | Startup |
| HOTELS_DS1 | Overpass/Fallback | 3+ | Startup |

---

## Testing External APIs

### Verify Real Data Loaded
```
# Check flights
curl http://localhost:8080/ords/freepdb1/tourism/federation/flights

# Check currencies  
curl http://localhost:8080/ords/freepdb1/tourism/federation/currencies

# Health check
curl http://localhost:8080/health
```

---

## Compliance & Attribution

- **OpenSky Network**: Academic use allowed (2000-4000 requests/day)
- **ECB**: Public data, no authentication required
- **OpenStreetMap**: CC BY-SA license, attribution required

All external data sources are publicly accessible and used within terms of service for academic projects.

---

**Last Updated**: April 7, 2026  
**Status**: ✅ All real external APIs integrated and tested
