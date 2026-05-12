-- ============================================================================
-- SparkSQL OLAP Views: Tourism Analytical Integration Model
-- Consolidation + Dimensional (ROLAP) + Analytical Views
-- ============================================================================

-- ============================================================================
-- (1) CONSOLIDATION VIEWS - JOIN across different data sources
-- ============================================================================

-- Consolidation 1: Hotel bookings with hotel details (DS1_PG + DS1_PG)
CREATE OR REPLACE VIEW V_CONSOLIDATION_HOTEL_BOOKINGS AS
SELECT
    CAST(b.booking_id AS INT) AS booking_id,
    CAST(b.tourist_id AS INT) AS tourist_id,
    CAST(b.hotel_id AS INT) AS hotel_id,
    t.first_name AS tourist_first_name,
    t.last_name AS tourist_last_name,
    t.country AS tourist_country,
    h.name AS hotel_name,
    h.city AS hotel_city,
    h.country AS hotel_country,
    CAST(h.star_rating AS INT) AS hotel_star_rating,
    CAST(h.price_per_night AS DOUBLE) AS price_per_night,
    b.check_in_date,
    b.check_out_date,
    CAST(b.num_guests AS INT) AS num_guests,
    CAST(b.total_amount AS DOUBLE) AS total_amount,
    b.booking_status,
    b.booking_date
FROM DS_SQL_BookingView b
JOIN DS_SQL_TouristView t ON b.tourist_id = t.tourist_id
JOIN DS_SQL_HotelView h ON b.hotel_id = h.hotel_id;

-- Consolidation 2: MongoDB bookings with currency conversion rates (DS3 + DS3)
CREATE OR REPLACE VIEW V_CONSOLIDATION_MONGO_BOOKINGS_CURRENCY AS
SELECT
    mb.booking_id,
    mb.guest_first_name,
    mb.guest_last_name,
    mb.guest_country,
    mb.destination,
    mb.travel_type,
    mb.start_date,
    mb.end_date,
    CAST(mb.duration_days AS INT) AS duration_days,
    CAST(mb.total_eur AS DOUBLE) AS total_eur,
    mb.payment_status,
    c.currency_code AS local_currency_code,
    CAST(c.exchange_rate AS DOUBLE) AS local_exchange_rate,
    CAST(mb.total_eur AS DOUBLE) * CAST(c.exchange_rate AS DOUBLE) AS total_local_currency
FROM DS_NoSQL_MongoBookingView mb
LEFT JOIN DS_NoSQL_CurrencyView c ON c.currency_code = 'RON';

-- Consolidation 3: Flights with airline details (DS2_CSV + DS2_CSV)
CREATE OR REPLACE VIEW V_CONSOLIDATION_FLIGHTS_AIRLINES AS
SELECT
    f.flight_id,
    f.airline AS airline_code,
    a.airline_name,
    a.alliance,
    f.departure_city,
    f.arrival_city,
    CAST(f.flight_duration AS INT) AS flight_duration_min,
    f.aircraft_type,
    CAST(f.capacity AS INT) AS capacity,
    CAST(f.seats_available AS INT) AS seats_available,
    CAST(f.economy_price AS DOUBLE) AS economy_price,
    CAST(f.business_price AS DOUBLE) AS business_price,
    f.days_operating
FROM DS_DOC_FlightView f
JOIN DS_DOC_AirlineView a ON f.airline = a.airline_code;

-- ---- CROSS-SOURCE CONSOLIDATION VIEWS ----

-- Consolidation 4: Destination Access - Hotels × Flights (DS1_PG × DS2_CSV)
-- Links hotels to flights arriving in the same city
CREATE OR REPLACE VIEW V_CONSOLIDATION_DESTINATION_ACCESS AS
SELECT
    h.hotel_id,
    h.hotel_name,
    h.star_rating,
    h.city,
    h.country AS hotel_country,
    h.price_per_night,
    f.flight_id,
    f.airline_code,
    f.airline_name,
    f.departure_city,
    f.economy_price,
    f.business_price,
    f.flight_duration_min,
    f.seats_available,
    CAST(h.price_per_night AS DOUBLE) + CAST(f.economy_price AS DOUBLE) AS min_trip_cost_eur,
    CAST(h.price_per_night AS DOUBLE) + CAST(f.business_price AS DOUBLE) AS premium_trip_cost_eur
FROM DIM_HOTEL h
JOIN V_CONSOLIDATION_FLIGHTS_AIRLINES f ON UPPER(h.city) = UPPER(f.arrival_city);

-- Consolidation 5: Cross-Source Bookings - Hotel × Travel (DS1_PG × DS3_MongoDB)
-- Connects hotel bookings with travel agency bookings for the same destination
CREATE OR REPLACE VIEW V_CONSOLIDATION_CROSS_BOOKINGS AS
SELECT
    hb.booking_id AS hotel_booking_id,
    hb.tourist_first_name,
    hb.tourist_last_name,
    hb.tourist_country,
    hb.hotel_name,
    hb.hotel_city,
    hb.total_amount AS hotel_total_eur,
    mb.booking_id AS travel_booking_id,
    mb.guest_first_name,
    mb.guest_last_name,
    mb.guest_country,
    mb.destination,
    mb.travel_type,
    CAST(mb.total_eur AS DOUBLE) AS travel_total_eur,
    CAST(hb.total_amount AS DOUBLE) + CAST(mb.total_eur AS DOUBLE) AS combined_revenue_eur
FROM V_CONSOLIDATION_HOTEL_BOOKINGS hb
JOIN DS_NoSQL_MongoBookingView mb ON UPPER(hb.hotel_city) = UPPER(mb.destination);

-- Consolidation 6: Hotel Prices in Multiple Currencies (DS1_PG × DS3_MongoDB)
-- Shows each hotel's price per night converted to all available currencies
CREATE OR REPLACE VIEW V_CONSOLIDATION_HOTEL_PRICES_MULTI_CURRENCY AS
SELECT
    h.hotel_id,
    h.hotel_name,
    h.city,
    h.star_rating,
    h.price_per_night AS price_eur,
    c.currency_code,
    c.currency_name,
    c.symbol,
    CAST(h.price_per_night AS DOUBLE) * CAST(c.exchange_rate AS DOUBLE) AS price_local,
    c.region AS currency_region
FROM DIM_HOTEL h
CROSS JOIN DS_NoSQL_CurrencyView c;

-- Consolidation 7: Full Integrated Tourism Fact (DS1_PG × DS2_CSV × DS3_MongoDB)
-- Master cross-source view joining hotels, flights, and travel bookings
CREATE OR REPLACE VIEW V_FACT_INTEGRATED_TOURISM AS
SELECT
    mb.booking_id AS travel_booking_id,
    mb.destination,
    mb.travel_type,
    mb.guest_country,
    CAST(mb.total_eur AS DOUBLE) AS travel_revenue_eur,
    mb.payment_status,
    h.hotel_id,
    h.hotel_name,
    h.star_rating AS hotel_stars,
    h.price_per_night AS hotel_price_eur,
    h.country AS hotel_country,
    f.flight_id,
    f.airline_name,
    f.departure_city,
    f.economy_price AS flight_economy_price,
    f.flight_duration_min,
    CAST(h.price_per_night AS DOUBLE) + CAST(f.economy_price AS DOUBLE) + CAST(mb.total_eur AS DOUBLE) AS total_integrated_cost_eur
FROM DS_NoSQL_MongoBookingView mb
JOIN DIM_HOTEL h ON UPPER(mb.destination) = UPPER(h.city)
JOIN V_CONSOLIDATION_FLIGHTS_AIRLINES f ON UPPER(mb.destination) = UPPER(f.arrival_city);


-- ============================================================================
-- (2) ROLAP DIMENSIONAL SCHEMA
-- ============================================================================

-- ---- DIMENSION VIEWS ----

-- DIM: Hotel Stars Category (from CSV)
CREATE OR REPLACE VIEW DIM_HOTEL_STARS AS
SELECT
    CAST(star_category AS INT) AS star_category,
    star_label,
    description
FROM DS_DOC_HotelStarsView;

-- DIM: Tourist Age Groups (from CSV)
CREATE OR REPLACE VIEW DIM_TOURIST_AGE AS
SELECT
    CAST(age_group_id AS INT) AS age_group_id,
    age_range,
    label
FROM DS_DOC_TouristAgeView;

-- DIM: Calendar/Period (from CSV)
CREATE OR REPLACE VIEW DIM_PERIOD AS
SELECT
    period_date,
    CAST(year AS INT) AS year,
    CAST(month AS INT) AS month,
    CAST(day AS INT) AS day,
    CAST(quarter AS INT) AS quarter,
    season,
    is_high_season
FROM DS_DOC_PeriodView;

-- DIM: Destination (derived from MongoDB bookings)
CREATE OR REPLACE VIEW DIM_DESTINATION AS
SELECT DISTINCT
    destination,
    travel_type
FROM DS_NoSQL_MongoBookingView;

-- DIM: Hotels (from PostgreSQL)
CREATE OR REPLACE VIEW DIM_HOTEL AS
SELECT
    CAST(hotel_id AS INT) AS hotel_id,
    name AS hotel_name,
    CAST(star_rating AS INT) AS star_rating,
    city,
    country,
    CAST(capacity AS INT) AS capacity,
    CAST(price_per_night AS DOUBLE) AS price_per_night
FROM DS_SQL_HotelView;


-- ---- FACT VIEWS ----

-- FACT: Hotel Bookings (from PostgreSQL - transactional data)
CREATE OR REPLACE VIEW FACT_HOTEL_BOOKINGS AS
SELECT
    CAST(b.booking_id AS INT) AS booking_id,
    CAST(b.tourist_id AS INT) AS tourist_id,
    CAST(b.hotel_id AS INT) AS hotel_id,
    b.check_in_date,
    b.check_out_date,
    CAST(b.num_guests AS INT) AS num_guests,
    CAST(b.total_amount AS DOUBLE) AS total_amount,
    b.booking_status,
    b.booking_date
FROM DS_SQL_BookingView b;

-- FACT: Travel Bookings (from MongoDB - agency booking data)
CREATE OR REPLACE VIEW FACT_TRAVEL_BOOKINGS AS
SELECT
    mb.booking_id,
    mb.booking_date,
    mb.guest_country,
    mb.guest_age_group,
    mb.destination,
    mb.travel_type,
    CAST(mb.duration_days AS INT) AS duration_days,
    CAST(mb.subtotal_eur AS DOUBLE) AS subtotal_eur,
    CAST(mb.tax_amount AS DOUBLE) AS tax_amount,
    CAST(mb.total_eur AS DOUBLE) AS total_eur,
    mb.payment_status,
    mb.agent_id
FROM DS_NoSQL_MongoBookingView mb;


-- ============================================================================
-- (3) OLAP ANALYTICAL VIEWS (aggregations, ROLLUP, CUBE)
-- ============================================================================

-- OLAP 1: Revenue by Destination (SUM, AVG, COUNT)
CREATE OR REPLACE VIEW OLAP_REVENUE_BY_DESTINATION AS
SELECT
    destination,
    COUNT(*) AS total_bookings,
    SUM(total_eur) AS total_revenue_eur,
    AVG(total_eur) AS avg_revenue_eur,
    AVG(duration_days) AS avg_duration_days
FROM FACT_TRAVEL_BOOKINGS
GROUP BY destination;

-- OLAP 2: Revenue by Travel Type (SUM, AVG, COUNT)
CREATE OR REPLACE VIEW OLAP_REVENUE_BY_TRAVEL_TYPE AS
SELECT
    travel_type,
    COUNT(*) AS total_bookings,
    SUM(total_eur) AS total_revenue_eur,
    AVG(total_eur) AS avg_revenue_eur
FROM FACT_TRAVEL_BOOKINGS
GROUP BY travel_type;

-- OLAP 3: Revenue CUBE - multi-dimensional analysis (CUBE)
CREATE OR REPLACE VIEW OLAP_REVENUE_CUBE AS
SELECT
    ROW_NUMBER() OVER (ORDER BY destination, travel_type, guest_country) AS row_id,
    destination,
    travel_type,
    guest_country,
    COUNT(*) AS total_bookings,
    SUM(total_eur) AS total_revenue_eur,
    AVG(total_eur) AS avg_revenue_eur
FROM FACT_TRAVEL_BOOKINGS
GROUP BY destination, travel_type, guest_country
WITH CUBE;

-- OLAP 4: Hotel Occupancy Analysis (from PostgreSQL bookings + hotels)
CREATE OR REPLACE VIEW OLAP_HOTEL_OCCUPANCY AS
SELECT
    h.name AS hotel_name,
    h.city,
    h.country,
    CAST(h.star_rating AS INT) AS star_rating,
    COUNT(*) AS total_bookings,
    SUM(CAST(b.total_amount AS DOUBLE)) AS total_revenue_eur,
    AVG(CAST(h.price_per_night AS DOUBLE)) AS avg_price_per_night
FROM DS_SQL_BookingView b
JOIN DS_SQL_HotelView h ON b.hotel_id = h.hotel_id
GROUP BY h.name, h.city, h.country, h.star_rating;

-- OLAP 5: Revenue ROLLUP by Destination and Travel Type
CREATE OR REPLACE VIEW OLAP_REVENUE_ROLLUP AS
SELECT
    destination,
    travel_type,
    COUNT(*) AS total_bookings,
    SUM(total_eur) AS total_revenue_eur,
    AVG(total_eur) AS avg_revenue_eur,
    MIN(total_eur) AS min_revenue_eur,
    MAX(total_eur) AS max_revenue_eur
FROM FACT_TRAVEL_BOOKINGS
GROUP BY destination, travel_type
WITH ROLLUP;

-- OLAP 6: Flight Route Analytics (from CSV data)
CREATE OR REPLACE VIEW OLAP_FLIGHT_ANALYTICS AS
SELECT
    fa.airline_name,
    fa.alliance,
    COUNT(*) AS total_flights,
    AVG(fa.flight_duration_min) AS avg_flight_duration,
    AVG(fa.economy_price) AS avg_economy_price,
    AVG(fa.business_price) AS avg_business_price,
    SUM(fa.capacity) AS total_capacity,
    SUM(fa.seats_available) AS total_seats_available
FROM V_CONSOLIDATION_FLIGHTS_AIRLINES fa
GROUP BY fa.airline_name, fa.alliance;


-- ============================================================================
-- (4) WINDOW ANALYTICAL VIEWS (ROW_NUMBER, RANK, SUM OVER, LAG/LEAD)
-- ============================================================================

-- WV 1: Running Total Revenue per Destination (SUM OVER + ORDER BY)
-- Shows cumulative revenue as bookings accumulate, partitioned by destination
CREATE OR REPLACE VIEW WV_REVENUE_RUNNING_TOTAL AS
SELECT
    booking_id,
    destination,
    travel_type,
    total_eur,
    booking_date,
    SUM(total_eur) OVER (PARTITION BY destination ORDER BY booking_date) AS running_total_eur,
    COUNT(*) OVER (PARTITION BY destination ORDER BY booking_date) AS running_booking_count
FROM FACT_TRAVEL_BOOKINGS;

-- WV 2: Hotel Revenue Ranking (RANK + DENSE_RANK)
-- Ranks hotels by total revenue and booking count
CREATE OR REPLACE VIEW WV_HOTEL_REVENUE_RANK AS
SELECT
    h.hotel_name,
    h.city,
    h.star_rating,
    COUNT(*) AS total_bookings,
    SUM(cb.total_amount) AS total_revenue_eur,
    AVG(cb.total_amount) AS avg_booking_value,
    RANK() OVER (ORDER BY SUM(cb.total_amount) DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS bookings_rank
FROM V_CONSOLIDATION_HOTEL_BOOKINGS cb
JOIN DIM_HOTEL h ON cb.hotel_id = h.hotel_id
GROUP BY h.hotel_name, h.city, h.star_rating;

-- WV 3: Booking Amount Deviation from Destination Average (AVG OVER + difference)
-- Compares each booking's value to its destination's average
CREATE OR REPLACE VIEW WV_BOOKING_AVG_DIFF AS
SELECT
    booking_id,
    destination,
    guest_country,
    total_eur,
    AVG(total_eur) OVER (PARTITION BY destination) AS destination_avg_eur,
    total_eur - AVG(total_eur) OVER (PARTITION BY destination) AS diff_from_avg,
    ROW_NUMBER() OVER (PARTITION BY destination ORDER BY total_eur DESC) AS rank_in_destination
FROM FACT_TRAVEL_BOOKINGS;

-- WV 4: Consecutive Booking Comparison (LAG / LEAD)
-- Shows previous and next booking amounts per destination for trend analysis
CREATE OR REPLACE VIEW WV_BOOKING_LAG_LEAD AS
SELECT
    booking_id,
    destination,
    travel_type,
    booking_date,
    total_eur,
    LAG(total_eur, 1) OVER (PARTITION BY destination ORDER BY booking_date) AS prev_booking_eur,
    LEAD(total_eur, 1) OVER (PARTITION BY destination ORDER BY booking_date) AS next_booking_eur,
    total_eur - LAG(total_eur, 1) OVER (PARTITION BY destination ORDER BY booking_date) AS change_from_prev
FROM FACT_TRAVEL_BOOKINGS;

-- WV 5: Flight Price Ranking per Alliance (ROW_NUMBER + FIRST_VALUE / LAST_VALUE)
-- Ranks flights by economy price within each alliance, showing cheapest and most expensive
CREATE OR REPLACE VIEW WV_FLIGHT_PRICE_RANK AS
SELECT
    flight_id,
    airline_name,
    alliance,
    departure_city,
    arrival_city,
    economy_price,
    business_price,
    ROW_NUMBER() OVER (PARTITION BY alliance ORDER BY economy_price ASC) AS price_rank_asc,
    FIRST_VALUE(economy_price) OVER (PARTITION BY alliance ORDER BY economy_price ASC) AS cheapest_in_alliance,
    LAST_VALUE(economy_price) OVER (PARTITION BY alliance ORDER BY economy_price ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS priciest_in_alliance
FROM V_CONSOLIDATION_FLIGHTS_AIRLINES;
