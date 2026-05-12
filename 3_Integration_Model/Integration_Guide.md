# TEMA L2 & L3: Integration & Analytical Model
# SparkSQL Federation + OLAP Analytics

## Overview

This section implements:
- **TEMA L2**: Federated data access via SparkSQL views that query 3 heterogeneous REST microservices
- **TEMA L3**: Analytical OLAP model with consolidation, dimensional (ROLAP), aggregation, and window views

**Integration Engine**: Apache SparkSQL (Hive Thrift Server on port 10000)  
**Access Mechanism**: `java_method()` UDF → HTTP GET → JSON → `from_json()` + `explode()`  
**Script**: `SparkSQL_OLAP.sql` (run in DBeaver/DataGrip via Hive JDBC)

---

## TEMA L2: Federated Access Model

### Architecture
SparkSQL acts as a virtual federated database. Each data source is accessed through a dedicated Spring Boot microservice that exposes REST/JSON endpoints. SparkSQL views call these endpoints at query time.

### Data Sources & Access Views

#### DS1: PostgreSQL (Relational) — via DSA-SQL-JPAService (:8090)
| View | Endpoint | Columns |
|------|----------|---------|
| `DS_SQL_TouristView` | `/rest/tourism/TouristView` | tourist_id, first_name, last_name, email, country, birth_date |
| `DS_SQL_HotelView` | `/rest/tourism/HotelView` | hotel_id, name, star_rating, city, country, capacity, price_per_night |
| `DS_SQL_BookingView` | `/rest/tourism/BookingView` | booking_id, tourist_id, hotel_id, check_in_date, check_out_date, num_guests, total_amount, booking_status |

#### DS2: CSV Files (Document) — via DSA-DOC-CSVService (:8097)
| View | Endpoint | Columns |
|------|----------|---------|
| `DS_DOC_AirlineView` | `/rest/csv/AirlineView` | airline_code, airline_name, country, fleet_size, founded_year, alliance |
| `DS_DOC_FlightView` | `/rest/csv/FlightView` | flight_id, airline, departure_city, arrival_city, economy_price, business_price, flight_duration |
| `DS_DOC_RouteView` | `/rest/csv/RouteView` | route_id, departure_city, arrival_city, distance_km, frequency_per_week |
| `DS_DOC_HotelStarsView` | `/rest/csv/HotelStarsView` | star_category, star_label, description |
| `DS_DOC_TouristAgeView` | `/rest/csv/TouristAgeView` | age_group_id, age_range, label |
| `DS_DOC_PeriodView` | `/rest/csv/PeriodView` | period_date, year, month, quarter, season, is_high_season |

#### DS3: MongoDB (NoSQL) — via DSA-NoSQL-MongoDBService (:8093)
| View | Endpoint | Columns |
|------|----------|---------|
| `DS_NoSQL_MongoBookingView` | `/rest/mongodb/MongoBookingView` | booking_id, guest_first_name, guest_country, destination, travel_type, duration_days, total_eur, payment_status |
| `DS_NoSQL_CurrencyView` | `/rest/mongodb/CurrencyView` | currency_code, currency_name, exchange_rate, region, symbol |

### Access Pattern (repeated for each view)
```sql
CREATE OR REPLACE VIEW DS_SQL_HotelView AS
SELECT r.hotelId AS hotel_id, r.name AS name, ...
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/HotelView'),
            'array<struct<hotelId:string,name:string,...>>'
        )
    ) AS r
) t;
```

---

## TEMA L3: Analytical OLAP Model

All views defined in `SparkSQL_OLAP.sql`, organized in 4 sections:

### (1) Consolidation Views — Cross-Source JOINs

| View | Sources | JOIN Key | Purpose |
|------|---------|----------|---------|
| `V_CONSOLIDATION_HOTEL_BOOKINGS` | DS1 × DS1 | booking.hotel_id = hotel.hotel_id | Hotel bookings enriched with tourist + hotel details |
| `V_CONSOLIDATION_MONGO_BOOKINGS_CURRENCY` | DS3 × DS3 | currency_code = 'RON' | MongoDB bookings with local currency conversion |
| `V_CONSOLIDATION_FLIGHTS_AIRLINES` | DS2 × DS2 | flight.airline = airline.airline_code | Flights enriched with airline details |
| `V_CONSOLIDATION_DESTINATION_ACCESS` | **DS1 × DS2** | hotel.city = flight.arrival_city | Hotels linked to arriving flights (trip cost calc) |
| `V_CONSOLIDATION_CROSS_BOOKINGS` | **DS1 × DS3** | hotel_city = destination | Hotel bookings matched with travel agency bookings |
| `V_CONSOLIDATION_HOTEL_PRICES_MULTI_CURRENCY` | **DS1 × DS3** | CROSS JOIN all currencies | Hotel prices in every available currency |
| `V_FACT_INTEGRATED_TOURISM` | **DS1 × DS2 × DS3** | destination = city = arrival_city | Full 3-source integration fact |

### (2) ROLAP Dimensional Schema

#### Dimension Views
| View | Source | Role |
|------|--------|------|
| `DIM_HOTEL_STARS` | DS2 (CSV) | Hotel star category labels |
| `DIM_TOURIST_AGE` | DS2 (CSV) | Tourist age group classification |
| `DIM_PERIOD` | DS2 (CSV) | Calendar dimension (year, quarter, season, high season) |
| `DIM_DESTINATION` | DS3 (MongoDB) | Distinct destinations + travel types |
| `DIM_HOTEL` | DS1 (PostgreSQL) | Hotel master dimension |

#### Fact Views
| View | Source | Measures |
|------|--------|----------|
| `FACT_HOTEL_BOOKINGS` | DS1 (PostgreSQL) | num_guests, total_amount, booking_status |
| `FACT_TRAVEL_BOOKINGS` | DS3 (MongoDB) | duration_days, subtotal_eur, tax_amount, total_eur |

### (3) OLAP Analytical Views (Aggregation)

| View | Technique | Purpose |
|------|-----------|---------|
| `OLAP_REVENUE_BY_DESTINATION` | GROUP BY + SUM/AVG/COUNT | Revenue and duration stats per destination |
| `OLAP_REVENUE_BY_TRAVEL_TYPE` | GROUP BY + SUM/AVG | Revenue breakdown by travel type |
| `OLAP_REVENUE_CUBE` | **CUBE** (destination × travel_type × guest_country) | Multi-dimensional revenue analysis with all subtotal combinations |
| `OLAP_HOTEL_OCCUPANCY` | GROUP BY + JOIN | Hotel performance (bookings, revenue, avg price) |
| `OLAP_REVENUE_ROLLUP` | **ROLLUP** (destination → travel_type) | Hierarchical subtotals from detail to grand total |
| `OLAP_FLIGHT_ANALYTICS` | GROUP BY alliance | Airline/alliance level flight statistics |

### (4) Window Analytical Views

| View | Technique | Purpose |
|------|-----------|---------|
| `WV_REVENUE_RUNNING_TOTAL` | SUM() OVER (PARTITION BY ... ORDER BY) | Cumulative revenue per destination over time |
| `WV_HOTEL_REVENUE_RANK` | RANK() + DENSE_RANK() | Hotels ranked by total revenue and booking count |
| `WV_BOOKING_AVG_DIFF` | AVG() OVER + ROW_NUMBER() | Each booking's deviation from destination average |
| `WV_BOOKING_LAG_LEAD` | LAG() / LEAD() | Consecutive booking comparison for trend detection |
| `WV_FLIGHT_PRICE_RANK` | ROW_NUMBER() + FIRST_VALUE / LAST_VALUE | Flight price ranking within each airline alliance |

---

## How to Deploy

1. Start all services: `docker compose -f docker-compose-j4di.yml up --build`
2. Wait for SparkSQL health check (port 10000 ready, ~2 min)
3. Connect DBeaver/DataGrip to `jdbc:hive2://localhost:10000/default` (no user/password)
4. Run scripts in order:
   - `2_Access_Model/DS_SQL_PG.sql`
   - `2_Access_Model/DS_DOC_CSV.sql`
   - `2_Access_Model/DS_NoSQL_MongoDB.sql`
   - `3_Integration_Model/SparkSQL_OLAP.sql`
5. Query any view: `SELECT * FROM OLAP_REVENUE_CUBE LIMIT 20;`
6. DSA-WEB-RESTService (`:8096`) exposes OLAP views as REST endpoints automatically

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
