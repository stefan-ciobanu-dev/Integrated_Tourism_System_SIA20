# Implementation Plan — Tourism Analytics Platform

## Project Assessment Summary

### Required Architecture (Java4DI)
The university course mandates the **Java4DI (Java for Data Integration)** stratified architecture:
- **~5 Spring Boot microservices** (Access Model + Web Model)
- **SparkSQL** as integration/federation engine (downloaded from course portal)
- **4 SQL scripts** run in DBeaver/DataGrip against SparkSQL (Hive-JDBC port 10000)
- Three heterogeneous data sources: **PostgreSQL** (relational), **CSV** (document), **MongoDB** (NoSQL)

### Current State — Critical Architecture Mismatch
The existing project uses **Oracle DB + Node.js/Express**, which does **not** comply with the required Java4DI architecture. The entire runtime stack must be replaced.

| Component | Required | Current | Status |
|-----------|----------|---------|--------|
| Access Model Services | 3 Spring Boot apps | 1 Node.js Express server | **MISSING** |
| Integration Engine | SparkSQL (Hive-JDBC) | Oracle views (SQL) | **MISSING** |
| Web Model Service | 1 Spring Boot app (Hive-JDBC) | Node.js REST API | **MISSING** |
| Relational DB | PostgreSQL | Oracle 23ai | **WRONG DB** |
| NoSQL DB | MongoDB | None (JSON files on disk) | **MISSING** |
| Document Data | CSV files via Spring Boot | CSV files on disk | **NEEDS ADAPTATION** |
| SparkSQL Scripts | 4 SQL files | 0 | **MISSING** |
| OLAP Views | SparkSQL syntax | Oracle SQL syntax | **NEEDS REWRITE** |
| Docker Compose | PG + Mongo + 5 services + Spark | Oracle + ORDS | **NEEDS REWRITE** |

### What Can Be Reused
- Tourism domain concept and data model design
- Existing CSV files (`DS2_AIRLINES.csv`, `DS2_FLIGHTS.csv`, `DS2_ROUTES.csv`) — usable as-is by DSA-DOC-CSVService
- Existing JSON files (`DS3_AGENTS.json`, `DS3_BOOKINGS.json`, `DS3_CURRENCIES.json`) — can seed MongoDB
- OLAP analytical logic (ROLLUP, CUBE concepts) — needs SparkSQL syntax adaptation
- HTML dashboards — can serve as optional Web-UI complement

---

## Implementation Tasks

### Phase 1: Data Sources (Independent — can be parallelized)

#### TASK 1.1 — PostgreSQL Tourism Schema
**Goal**: Create the PostgreSQL relational database schema with tourism transactional data.

**What to create**:
- File: `sql/12_DS_PG_Schema_Tourism.sql`
- PostgreSQL schema `tourism` with tables:
  - `tourists` (tourist_id SERIAL PK, first_name, last_name, email, country, birth_date, registration_date)
  - `hotels` (hotel_id SERIAL PK, name, star_rating, city_code VARCHAR, address, price_per_night NUMERIC, capacity INT)
  - `bookings` (booking_id SERIAL PK, tourist_id FK, hotel_id FK, check_in_date DATE, check_out_date DATE, num_guests INT, total_amount NUMERIC, booking_status VARCHAR, booking_date DATE)
- Sample INSERT data: at least 50 tourists, 20 hotels across multiple cities, 200+ bookings spanning 2024-2026
- The `city_code` in hotels **MUST** match city codes used in MongoDB geographic data (Task 1.3)

**Key constraints**:
- Use consistent city_code values across PG and MongoDB (e.g., `BUC`, `BRA`, `CLJ`, `TMS`, `SIB`, `IAI`, `CTA`, `BCN`, `VIE`, `BUD`, `PRG`, `ROM`, `PAR`, `BER`, `AMS`)
- Date ranges for bookings: 2024-01-01 to 2026-12-31
- Booking statuses: CONFIRMED, CANCELLED, PENDING, COMPLETED
- Star ratings: 1-5
- Realistic price ranges per star rating

**Reference**: `specifications/requirements/fdbo_study_case/1_DateSources/` for pattern.

---

#### TASK 1.2 — CSV Data Files for DSA-DOC-CSVService
**Goal**: Create classification/dimension CSV files that the CSVService microservice will read.

**What to create** (place in `src/DSA-DOC-CSVService/src/main/resources/datasource/`):
1. `CTG_HOTEL_STARS.csv` — Hotel star rating categories
   - Columns: `STAR_RATING,CATEGORY_NAME,PRICE_RANGE_MIN,PRICE_RANGE_MAX`
   - Content: 5 rows (1-star Budget through 5-star Luxury)
2. `CTG_TOURIST_AGE.csv` — Tourist age group segments
   - Columns: `AGE_MIN,AGE_MAX,CATEGORY_NAME`
   - Content: 5-6 rows (18-25 Young, 26-35 Adult, 36-50 Middle-aged, 51-65 Senior, 66+ Elderly)
3. `CTG_AIRLINES.csv` — Airline categories (reuse from existing `data_sources/DS2_AIRLINES.csv`)
   - Columns: `AIRLINE_CODE,AIRLINE_NAME,COUNTRY,FLEET_SIZE,FOUNDED_YEAR,ALLIANCE`
4. `Periods_Tourism.csv` — Calendar dimension with tourism seasons
   - Columns: `PERIOD_DATE,YEAR,MONTH,DAY,QUARTER,SEASON,IS_HIGH_SEASON`
   - Content: All dates for 2024-2026 (1096 rows)
   - Seasons: High (Jun-Aug), Shoulder (Apr-May, Sep-Oct), Low (Nov-Mar)

**Reference**: `specifications/requirements/dsa_study_case/DSA-DOC-CSVService/` for service structure.

---

#### TASK 1.3 — MongoDB Geographic Data
**Goal**: Create MongoDB seed data for the tourism geographic hierarchy.

**What to create**:
- File: `sql/mongo_init_tourism.js` (mongosh initialization script)
- Database: `tourism_geo`, Collection: `locations`
- Document structure (hierarchical):
```json
{
  "region_code": "TRA",
  "region_name": "Transylvania",
  "country": "Romania",
  "cities": [
    {
      "city_code": "BRA",
      "city_name": "Brașov",
      "population": 253200,
      "attractions": [
        {
          "attraction_id": "ATT001",
          "name": "Black Church",
          "type": "Monument",
          "annual_visitors": 500000
        }
      ]
    }
  ]
}
```
- At least 5 regions, 15 cities, 40 attractions
- City codes **MUST** match `hotels.city_code` in PostgreSQL (Task 1.1)
- Attraction types: Museum, Beach, Monument, Park, Church, Castle, Market, Cathedral, Square, Palace
- Also create a separate `travel_agents` collection from existing `data_sources/DS3_AGENTS.json`

**Reference**: `specifications/requirements/dsa_study_case/DSA-NoSQL-MongoDBService/` for the service pattern.

---

### Phase 2: Access Model Microservices (Depends on Phase 1)

#### TASK 2.1 — DSA-SQL-JPAService (PostgreSQL Access)
**Goal**: Create a Spring Boot REST microservice that connects to PostgreSQL via JPA and exposes tourism data as REST endpoints.

**What to create**: Complete Maven project at `src/DSA-SQL-JPAService/`

**Project structure**:
```
src/DSA-SQL-JPAService/
├── pom.xml
├── Dockerfile
└── src/main/
    ├── java/org/j4di/
    │   ├── DSASQLJPAServiceApplication.java
    │   ├── config/
    │   │   └── SecurityConfig.java
    │   ├── model/
    │   │   ├── TouristView.java      (JPA @Entity)
    │   │   ├── HotelView.java        (JPA @Entity)
    │   │   └── BookingView.java       (JPA @Entity)
    │   ├── repository/
    │   │   ├── TouristRepository.java (JpaRepository)
    │   │   ├── HotelRepository.java
    │   │   └── BookingRepository.java
    │   └── controller/
    │       └── RESTViewServiceJPA.java
    └── resources/
        └── application.properties
```

**Technical specs**:
- Spring Boot 3.3.5, Java 21, Maven, JAR packaging
- Dependencies: spring-boot-starter-web, spring-boot-starter-data-jpa, spring-boot-starter-security, postgresql (42.7.3), lombok, jackson-dataformat-xml
- Port: **8090**
- Context path: `/DSA-SQL-JPAService`
- REST endpoints (produce both JSON and XML):
  - `GET /rest/ping` — health check
  - `GET /rest/tourism/TouristView` — all tourists
  - `GET /rest/tourism/HotelView` — all hotels
  - `GET /rest/tourism/BookingView` — all bookings
- Pagination: `fetch_offset` and `fetch_size` query parameters
- Spring Security: basic auth with configurable user/password (default: `developer`/`iis`)
- PostgreSQL connection: `jdbc:postgresql://postgresql:5432/tourism`

**Dockerfile**: Multi-stage Maven build (maven:3.9-eclipse-temurin-21 → eclipse-temurin:21-jre-alpine)

**Reference**: `specifications/requirements/dsa_study_case/DSA-SQL-JPAService/DSA-SQL-JPAService/` — follow its exact package structure (`org.j4di`), controller pattern, and security config.

---

#### TASK 2.2 — DSA-DOC-CSVService (CSV File Access)
**Goal**: Create a Spring Boot REST microservice that reads CSV files from classpath and exposes them as REST endpoints.

**What to create**: Complete Maven project at `src/DSA-DOC-CSVService/`

**Project structure**:
```
src/DSA-DOC-CSVService/
├── pom.xml
├── Dockerfile
└── src/main/
    ├── java/org/j4di/
    │   ├── DSADOCCSVServiceApplication.java
    │   ├── config/
    │   │   └── SecurityConfig.java
    │   ├── connector/
    │   │   └── CSVDataSourceConnector.java
    │   ├── model/
    │   │   ├── HotelStarsCategoryView.java
    │   │   ├── TouristAgeCategoryView.java
    │   │   ├── AirlineCategoryView.java
    │   │   └── TourismPeriodView.java
    │   ├── viewbuilder/
    │   │   ├── HotelStarsViewBuilder.java
    │   │   ├── TouristAgeViewBuilder.java
    │   │   ├── AirlineViewBuilder.java
    │   │   └── TourismPeriodViewBuilder.java
    │   └── controller/
    │       └── RESTViewServiceCSV.java
    └── resources/
        ├── application.properties
        └── datasource/
            ├── CTG_HOTEL_STARS.csv
            ├── CTG_TOURIST_AGE.csv
            ├── CTG_AIRLINES.csv
            └── Periods_Tourism.csv
```

**Technical specs**:
- Spring Boot 3.3.5, Java 21, Maven, JAR packaging
- Dependencies: spring-boot-starter-web, spring-boot-starter-security, commons-csv (1.10.0), lombok, jackson-dataformat-xml
- Port: **8097**
- Context path: `/DSA-DOC-CSVService`
- `CSVDataSourceConnector`: reads CSV files from `classpath:datasource/` using Apache Commons CSV
- `ViewBuilder` classes: parse CSV rows into view model POJOs
- REST endpoints (produce both JSON and XML):
  - `GET /rest/ping` — health check
  - `GET /rest/ctg/HotelStarsView` — hotel star categories
  - `GET /rest/ctg/TouristAgeView` — age group categories
  - `GET /rest/ctg/AirlineView` — airline data
  - `GET /rest/periods/TourismPeriodView` — calendar/period data with seasons
- Spring Security: basic auth (developer/iis)

**Dockerfile**: Multi-stage Maven build

**Reference**: `specifications/requirements/dsa_study_case/DSA-DOC-CSVService/DSA-DOC-CSVService/` — follow its connector pattern, ViewBuilder pattern, and controller style.

---

#### TASK 2.3 — DSA-NoSQL-MongoDBService (MongoDB Access)
**Goal**: Create a Spring Boot REST microservice that connects to MongoDB and exposes flattened geographic data as REST endpoints.

**What to create**: Complete Maven project at `src/DSA-NoSQL-MongoDBService/`

**Project structure**:
```
src/DSA-NoSQL-MongoDBService/
├── pom.xml
├── Dockerfile
└── src/main/
    ├── java/org/j4di/
    │   ├── DSANoSQLMongoDBServiceApplication.java
    │   ├── config/
    │   │   └── SecurityConfig.java
    │   ├── connector/
    │   │   └── MongoDataSourceConnector.java
    │   ├── model/
    │   │   ├── RegionView.java
    │   │   ├── CityView.java
    │   │   ├── AttractionView.java
    │   │   └── TravelAgentView.java
    │   ├── viewbuilder/
    │   │   ├── RegionViewBuilder.java
    │   │   ├── CityViewBuilder.java
    │   │   ├── AttractionViewBuilder.java
    │   │   └── TravelAgentViewBuilder.java
    │   └── controller/
    │       └── RESTViewServiceMongoDB.java
    └── resources/
        └── application.properties
```

**Technical specs**:
- Spring Boot 3.3.5, Java 21, Maven, JAR packaging
- Dependencies: spring-boot-starter-web, spring-boot-starter-security, mongodb-driver-sync (4.8.1), lombok, jackson-dataformat-xml
- Port: **8093**
- Context path: `/DSA-NoSQL-MongoDBService`
- `MongoDataSourceConnector`: connects to MongoDB using native driver (NOT Spring Data MongoDB — follow the reference project pattern)
- `ViewBuilder` classes: flatten hierarchical MongoDB documents into tabular views
  - RegionViewBuilder: extract region-level data from each document
  - CityViewBuilder: flatten cities array with region reference
  - AttractionViewBuilder: flatten attractions nested in cities with city reference
  - TravelAgentViewBuilder: flatten travel_agents collection
- REST endpoints (produce both JSON and XML):
  - `GET /rest/ping` — health check
  - `GET /rest/geo/RegionView` — all regions (flattened)
  - `GET /rest/geo/CityView` — all cities with region_code
  - `GET /rest/geo/AttractionView` — all attractions with city_code
  - `GET /rest/agents/TravelAgentView` — all travel agents
- MongoDB URI: `mongodb://mongodb:27017/tourism_geo`
- Spring Security: basic auth (developer/iis)

**Dockerfile**: Multi-stage Maven build

**Reference**: `specifications/requirements/dsa_study_case/DSA-NoSQL-MongoDBService/DSA-NoSQL-MongoDBService/` — follow its connector/ViewBuilder pattern.

---

### Phase 3: SparkSQL Integration Scripts (Depends on Phase 2)

> **Prerequisite**: DSA-SparkSQL-Service must be downloaded from the course portal and started. It listens on port 9990 (REST) and port 10000 (Hive-JDBC). Connect via DBeaver with `jdbc:hive2://localhost:10000`.

#### TASK 3.1 — SparkSQL Views for PostgreSQL Service (DS_SQL_PG.sql)
**Goal**: Create SparkSQL views that invoke DSA-SQL-JPAService REST endpoints.

**What to create**: `sql/DS_SQL_PG.sql`

**Views to create** (using `java_method` + `from_json` + `schema_of_json` + `LATERAL VIEW explode` pattern):
- `DS_PG_TOURISTS` → calls `http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/TouristView`
- `DS_PG_HOTELS` → calls `http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/HotelView`
- `DS_PG_BOOKINGS` → calls `http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/BookingView`

**SparkSQL view creation pattern** (from reference):
```sql
CREATE OR REPLACE VIEW DS_PG_TOURISTS AS
SELECT row.*
FROM (
  SELECT from_json(
    java_method('org.j4di.spark.HTR', 'GET',
      'http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/TouristView',
      'developer', 'iis'),
    schema_of_json('[{"touristId":1,"firstName":"x","lastName":"x","email":"x","country":"x","birthDate":"2000-01-01","registrationDate":"2024-01-01"}]')
  ) AS data
) t
LATERAL VIEW explode(data) AS row;
```

Each view must include:
- Proper `schema_of_json` matching the entity field names from Task 2.1
- Basic auth credentials in the HTR.GET call
- A verification `SELECT * FROM <view> LIMIT 5;` query at the end

**Reference**: `specifications/requirements/dsa_study_case/DSA-SparkSQL-Service-v2026.2/` for the HTR class and view creation patterns.

---

#### TASK 3.2 — SparkSQL Views for CSV Service (DS_DOC_CSV.sql)
**Goal**: Create SparkSQL views that invoke DSA-DOC-CSVService REST endpoints.

**What to create**: `sql/DS_DOC_CSV.sql`

**Views to create**:
- `DS_DOC_CTG_HOTEL_STARS` → calls `http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/ctg/HotelStarsView`
- `DS_DOC_CTG_TOURIST_AGE` → calls `http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/ctg/TouristAgeView`
- `DS_DOC_CTG_AIRLINES` → calls `http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/ctg/AirlineView`
- `DS_DOC_PERIODS_TOURISM` → calls `http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/periods/TourismPeriodView`

Use same `java_method` + `from_json` + `schema_of_json` + `explode` pattern as Task 3.1.

**Reference**: Same as Task 3.1.

---

#### TASK 3.3 — SparkSQL Views for MongoDB Service (DS_NoSQL_MongoDB.sql)
**Goal**: Create SparkSQL views that invoke DSA-NoSQL-MongoDBService REST endpoints.

**What to create**: `sql/DS_NoSQL_MongoDB.sql`

**Views to create**:
- `DS_NOSQL_GEO_REGIONS` → calls `http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/geo/RegionView`
- `DS_NOSQL_GEO_CITIES` → calls `http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/geo/CityView`
- `DS_NOSQL_GEO_ATTRACTIONS` → calls `http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/geo/AttractionView`
- `DS_NOSQL_TRAVEL_AGENTS` → calls `http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/agents/TravelAgentView`

Use same `java_method` + `from_json` + `schema_of_json` + `explode` pattern as Task 3.1.

---

### Phase 4: Analytical Model (Depends on Phase 3)

#### TASK 4.1 — SparkSQL OLAP Analytical Views (SparkSQL_OLAP.sql)
**Goal**: Create a dimensional star schema in SparkSQL using the access views from Phase 3, then build OLAP analytical views with ROLLUP, CUBE, and GROUPING SETS.

**What to create**: `sql/SparkSQL_OLAP.sql`

**Section 1 — OLAP Dimension Views**:
- `OLAP_DIM_GEO_HIERARCHY` — from DS_NOSQL_GEO_REGIONS + DS_NOSQL_GEO_CITIES
  - Columns: region_code, region_name, country, city_code, city_name, population
- `OLAP_DIM_CALENDAR` — from DS_DOC_PERIODS_TOURISM
  - Columns: period_date, year, month, quarter, season, is_high_season
- `OLAP_DIM_HOTEL_CATEGORY` — from DS_DOC_CTG_HOTEL_STARS
  - Columns: star_rating, category_name, price_range_min, price_range_max
- `OLAP_DIM_TOURIST_AGE` — from DS_DOC_CTG_TOURIST_AGE
  - Columns: age_min, age_max, category_name
- `OLAP_DIM_HOTELS` — from DS_PG_HOTELS
  - Columns: hotel_id, name, star_rating, city_code, price_per_night, capacity

**Section 2 — OLAP Fact View**:
- `OLAP_FACTS_BOOKINGS` — JOIN of DS_PG_BOOKINGS + DS_PG_TOURISTS + DS_PG_HOTELS
  - Columns: booking_id, tourist_id, hotel_id, city_code, star_rating, check_in_date, total_amount, num_guests, stay_duration (calculated: check_out - check_in), tourist_country, tourist_age (calculated from birth_date)

**Section 3 — OLAP Analytical Views (with aggregations)**:
- `OLAP_VIEW_REVENUE_BY_REGION` — Revenue by Region → City using ROLLUP
  ```sql
  SELECT
    COALESCE(g.region_name, 'ALL REGIONS') as region_name,
    COALESCE(g.city_name, 'ALL CITIES') as city_name,
    SUM(f.total_amount) as total_revenue,
    COUNT(*) as booking_count,
    AVG(f.total_amount) as avg_booking_value
  FROM OLAP_FACTS_BOOKINGS f
  JOIN OLAP_DIM_HOTELS h ON f.hotel_id = h.hotel_id
  JOIN OLAP_DIM_GEO_HIERARCHY g ON h.city_code = g.city_code
  GROUP BY ROLLUP(g.region_name, g.city_name);
  ```
- `OLAP_VIEW_REVENUE_BY_CALENDAR` — Revenue by Year → Quarter → Month using ROLLUP
- `OLAP_VIEW_REVENUE_BY_HOTEL_CTG` — Revenue by Star Category → Hotel using ROLLUP
- `OLAP_VIEW_REVENUE_BY_TOURIST_AGE` — Revenue by Age Group using ROLLUP
- `OLAP_VIEW_REVENUE_BY_SEASON` — Revenue by Season × Region using CUBE
- `OLAP_VIEW_REVENUE_GEO_HOTEL` — Revenue by Region × Star Category using CUBE

**Each analytical view must use**:
- `ROLLUP` or `CUBE` or `GROUPING SETS` operators
- `GROUPING()` function to label subtotal rows
- `COALESCE` with grouping() to show "ALL ..." labels for rollup totals
- Aggregation functions: SUM, COUNT, AVG, MIN, MAX

**Set AUTOREST properties for each OLAP view** (for DSA-SparkSQL-Service auto-exposure):
```sql
ALTER VIEW OLAP_VIEW_REVENUE_BY_REGION SET TBLPROPERTIES('AUTOREST' = 'olap/revenue_by_region');
```

**Reference**: `specifications/requirements/fdbo_study_case/3_IntegrationAnalyticalModel/31_OLAP_Multidimensional_Analytical.sql` for OLAP patterns. Adapt Oracle syntax to SparkSQL.

---

### Phase 5: Web Model (Depends on Phase 4)

#### TASK 5.1 — DSA-WEB-RESTService (SparkSQL OLAP Exposure)
**Goal**: Create a Spring Boot microservice that connects to SparkSQL via Hive-JDBC and exposes OLAP views as REST endpoints.

**What to create**: Complete Maven project at `src/DSA-WEB-RESTService/`

**Project structure**:
```
src/DSA-WEB-RESTService/
├── pom.xml
├── Dockerfile
└── src/main/
    ├── java/org/j4di/
    │   ├── DSAWEBRESTServiceApplication.java
    │   ├── config/
    │   │   ├── SecurityConfig.java
    │   │   └── HiveDataSourceConfig.java
    │   ├── model/
    │   │   ├── OlapRevenueByRegion.java
    │   │   ├── OlapRevenueByCalendar.java
    │   │   ├── OlapRevenueByHotelCtg.java
    │   │   ├── OlapRevenueByTouristAge.java
    │   │   ├── OlapRevenueBySeason.java
    │   │   ├── OlapRevenueGeoHotel.java
    │   │   ├── DimGeoHierarchy.java
    │   │   ├── DimHotels.java
    │   │   └── DimCalendar.java
    │   ├── repository/
    │   │   └── (JPA repositories or custom JDBC templates)
    │   └── controller/
    │       └── RESTViewServiceOLAP.java
    └── resources/
        └── application.properties
```

**Technical specs**:
- Spring Boot 3.3.5, Java 21, Maven, JAR packaging
- Dependencies: spring-boot-starter-web, spring-boot-starter-data-jpa, spring-boot-starter-security, hive-jdbc driver, lombok, jackson-dataformat-xml
- Port: **8096**
- Context path: `/DSA-WEB-RESTService`
- DataSource config:
  - `spring.datasource.url=jdbc:hive2://dsa-sparksql:10000`
  - `spring.datasource.driver-class-name=org.apache.hive.jdbc.HiveDriver`
  - `spring.jpa.database-platform=org.hibernate.community.dialect.HiveDialect` (or custom)
- JPA Entities mapping to SparkSQL OLAP views (read-only, `@Immutable`)
- REST endpoints (produce both JSON and XML):
  - `GET /rest/ping` — health check
  - `GET /rest/olap/RevenueByRegionView` — geographic revenue analytics
  - `GET /rest/olap/RevenueByCalendarView` — time-based analytics
  - `GET /rest/olap/RevenueByHotelCtgView` — hotel category analytics
  - `GET /rest/olap/RevenueByTouristAgeView` — age group analytics
  - `GET /rest/olap/RevenueBySeasonView` — seasonal analytics
  - `GET /rest/olap/RevenueGeoHotelView` — geo × hotel category
  - `GET /rest/dim/GeoHierarchyView` — geographic dimension
  - `GET /rest/dim/HotelsView` — hotel dimension
  - `GET /rest/dim/CalendarView` — time dimension
- Pagination: `fetch_offset`, `fetch_size` query parameters
- Spring Security: basic auth (developer/iis)

**Dockerfile**: Multi-stage Maven build

**Reference**: `specifications/requirements/dsa_study_case/DSA-WEB-RESTService/DSA-WEB-RESTService/` — follow its exact structure, especially how it connects to Hive-JDBC.

---

#### TASK 5.2 — Web UI Dashboard (Optional Enhancement)
**Goal**: Adapt existing HTML/JS dashboards to consume data from DSA-WEB-RESTService endpoints instead of the Node.js server.

**What to modify**:
- Update `dashboard.html` (or create new `dashboard-sparksql.html`)
- Change API base URL from `http://localhost:8080/ords/...` to `http://localhost:8096/DSA-WEB-RESTService/rest/...`
- Add basic auth headers to fetch calls (Base64 encoded `developer:iis`)
- Keep existing charts (Chart.js) and reports structure
- This is complementary and optional per the teacher's message ("JavaScript-based, Vaadin sau SpringBoot MVC")

---

### Phase 6: Infrastructure (Depends on ALL above)

#### TASK 6.1 — Docker Compose Full Stack
**Goal**: Create a docker-compose.yml that orchestrates the entire Java4DI Tourism Analytics stack.

**What to create**: `docker-compose.yml` (replace existing)

**Services**:
| Service | Image | Port | Depends On |
|---------|-------|------|------------|
| `postgresql` | postgres:16-alpine | 5432 | — |
| `mongodb` | mongo:7.0 | 27017 | — |
| `dsa-sql-jpa` | (build from src/DSA-SQL-JPAService) | 8090 | postgresql |
| `dsa-doc-csv` | (build from src/DSA-DOC-CSVService) | 8097 | — |
| `dsa-nosql-mongodb` | (build from src/DSA-NoSQL-MongoDBService) | 8093 | mongodb |
| `dsa-sparksql` | (from course portal or custom) | 9990, 10000 | dsa-sql-jpa, dsa-doc-csv, dsa-nosql-mongodb |
| `dsa-web-rest` | (build from src/DSA-WEB-RESTService) | 8096 | dsa-sparksql |

**Configuration**:
- Single bridge network: `tourism-network`
- PostgreSQL init: mount `sql/12_DS_PG_Schema_Tourism.sql` to `/docker-entrypoint-initdb.d/`
- MongoDB init: mount `sql/mongo_init_tourism.js` to `/docker-entrypoint-initdb.d/`
- Health checks for each service
- Startup order via `depends_on` with `condition: service_healthy`
- Environment variables for all connection parameters

**Note**: The DSA-SparkSQL-Service is provided by the course portal. It should be downloaded and placed in `src/DSA-SparkSQL-Service/`. If a Docker image is available, reference it; otherwise, build from the downloaded project.

---

#### TASK 6.2 — README Documentation
**Goal**: Update README.md with operational instructions for the Java4DI architecture.

**What to include**:
- Architecture diagram (text-based)
- Prerequisites (Java 21, Maven, Docker)
- How to start: `docker compose up --build`
- Port mapping table
- How to connect DBeaver to SparkSQL: `jdbc:hive2://localhost:10000`
- Step-by-step: run the 4 SQL scripts in DBeaver after services are up
- Verification steps for end-to-end flow
- REST endpoint reference table with URLs and example curl commands

---

### Phase 7: Cleanup

#### TASK 7.1 — Archive Old Implementation
**Goal**: Move Oracle-specific and Node.js files to `_archive/`.

**Files to archive**:
- `server-simple.js` → `_archive/old_servers/`
- `package.json` → `_archive/`
- `database/TEMA_L2_COMPLETE_FINAL.sql` → `_archive/old_database_scripts/`
- `database/TEMA_L2_FEDERATED_ACCESS.sql` → `_archive/old_database_scripts/`
- `database/TEMA_L3_OLAP_VIEWS.sql` → `_archive/old_database_scripts/`
- `2_Data_Models/DS1_Hotels_Schema.sql` (empty) → delete
- `2_Data_Models/DS2_Flights_Schema.sql` → `_archive/old_database_scripts/`
- `2_Data_Models/DS3_Currency_Schema.sql` → `_archive/old_database_scripts/`

**Do NOT archive**:
- `data_sources/` — the CSV and JSON files are reusable
- `1_Data_Sources/P1_Case_Study_Design.md` — documentation, keep
- HTML dashboards — can be adapted in Task 5.2

---

## Execution Order & Dependencies

```
TASK 1.1 (PostgreSQL Schema)        ← independent
TASK 1.2 (CSV Files)                ← independent
TASK 1.3 (MongoDB Data)             ← independent
  ↓ (city_codes must be coordinated across 1.1 and 1.3)
TASK 2.1 (DSA-SQL-JPAService)       ← depends on 1.1
TASK 2.2 (DSA-DOC-CSVService)       ← depends on 1.2
TASK 2.3 (DSA-NoSQL-MongoDBService) ← depends on 1.3
  ↓
TASK 3.1 (DS_SQL_PG.sql)            ← depends on 2.1 + SparkSQL running
TASK 3.2 (DS_DOC_CSV.sql)           ← depends on 2.2 + SparkSQL running
TASK 3.3 (DS_NoSQL_MongoDB.sql)     ← depends on 2.3 + SparkSQL running
  ↓
TASK 4.1 (SparkSQL_OLAP.sql)        ← depends on 3.1 + 3.2 + 3.3
  ↓
TASK 5.1 (DSA-WEB-RESTService)      ← depends on 4.1
TASK 5.2 (Web UI - optional)        ← depends on 5.1
  ↓
TASK 6.1 (Docker Compose)           ← depends on ALL above
TASK 6.2 (README)                   ← depends on ALL above
  ↓
TASK 7.1 (Archive old files)        ← last step
```

## Key Cross-Cutting Concerns

1. **City Code Consistency**: Tasks 1.1 and 1.3 MUST agree on the same set of city codes. Define them first:
   - Romania: `BUC` (Bucharest), `BRA` (Brașov), `CLJ` (Cluj-Napoca), `TMS` (Timișoara), `SIB` (Sibiu), `IAI` (Iași), `CTA` (Constanța)
   - Europe: `VIE` (Vienna), `BUD` (Budapest), `PRG` (Prague), `BCN` (Barcelona), `ROM` (Rome), `PAR` (Paris), `BER` (Berlin), `AMS` (Amsterdam)

2. **Dual Format Output**: All REST endpoints MUST support both `application/json` AND `application/xml`. Use `produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE}` on every `@RequestMapping`. Include `jackson-dataformat-xml` in all pom.xml files.

3. **Package Naming**: All Java classes use `org.j4di` as base package (matching reference projects).

4. **Security**: All services use Spring Security with basic auth. Default credentials: `developer`/`iis` (matching reference).

5. **Data Volume**: PostgreSQL should have substantial data (50+ tourists, 20+ hotels, 200+ bookings) to make OLAP analytics meaningful.

6. **SparkSQL Service**: Must be downloaded from the course portal. It is NOT something we build — it's provided. Place in `src/DSA-SparkSQL-Service/` and start with `mvn spring-boot:run` or via Docker.
