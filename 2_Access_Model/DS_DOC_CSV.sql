-- ============================================================================
-- SparkSQL: DS2 - CSV Data Source Views (via CSV REST Service)
-- Target: DSA-DOC-CSVService on port 8097
-- ============================================================================

CREATE OR REPLACE VIEW DS_DOC_AirlineView AS
SELECT
    r.airlineCode  AS airline_code,
    r.airlineName  AS airline_name,
    r.country      AS country,
    r.fleetSize    AS fleet_size,
    r.foundedYear  AS founded_year,
    r.alliance     AS alliance,
    r.website      AS website
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/AirlineView'),
            'array<struct<airlineCode:string,airlineName:string,country:string,fleetSize:string,foundedYear:string,alliance:string,website:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_DOC_FlightView AS
SELECT
    r.flightId       AS flight_id,
    r.airline        AS airline,
    r.departureCity  AS departure_city,
    r.arrivalCity    AS arrival_city,
    r.departureTime  AS departure_time,
    r.arrivalTime    AS arrival_time,
    r.flightDuration AS flight_duration,
    r.aircraftType   AS aircraft_type,
    r.capacity       AS capacity,
    r.seatsAvailable AS seats_available,
    r.economyPrice   AS economy_price,
    r.businessPrice  AS business_price,
    r.daysOperating  AS days_operating,
    r.operatingPeriod AS operating_period
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/FlightView'),
            'array<struct<flightId:string,airline:string,departureCity:string,arrivalCity:string,departureTime:string,arrivalTime:string,flightDuration:string,aircraftType:string,capacity:string,seatsAvailable:string,economyPrice:string,businessPrice:string,daysOperating:string,operatingPeriod:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_DOC_RouteView AS
SELECT
    r.routeId           AS route_id,
    r.departureCity     AS departure_city,
    r.arrivalCity       AS arrival_city,
    r.distanceKm        AS distance_km,
    r.frequencyPerWeek  AS frequency_per_week,
    r.averageFlightTime AS average_flight_time,
    r.routeType         AS route_type
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/RouteView'),
            'array<struct<routeId:string,departureCity:string,arrivalCity:string,distanceKm:string,frequencyPerWeek:string,averageFlightTime:string,routeType:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_DOC_HotelStarsView AS
SELECT
    r.starCategory AS star_category,
    r.starLabel    AS star_label,
    r.description  AS description
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/HotelStarsView'),
            'array<struct<starCategory:string,starLabel:string,description:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_DOC_TouristAgeView AS
SELECT
    r.ageGroupId AS age_group_id,
    r.ageRange   AS age_range,
    r.label      AS label
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/TouristAgeView'),
            'array<struct<ageGroupId:string,ageRange:string,label:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_DOC_PeriodView AS
SELECT
    r.periodDate   AS period_date,
    r.year         AS year,
    r.month        AS month,
    r.day          AS day,
    r.quarter      AS quarter,
    r.season       AS season,
    r.isHighSeason AS is_high_season
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-doc-csv:8097/DSA-DOC-CSVService/rest/csv/PeriodView'),
            'array<struct<periodDate:string,year:string,month:string,day:string,quarter:string,season:string,isHighSeason:string>>'
        )
    ) AS r
) t;
