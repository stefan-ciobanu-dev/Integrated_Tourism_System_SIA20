-- ============================================================================
-- SparkSQL: DS1 - PostgreSQL Data Source Views (via JPA REST Service)
-- Target: DSA-SQL-JPAService on port 8090
-- ============================================================================

CREATE OR REPLACE VIEW DS_SQL_TouristView AS
SELECT
    r.touristId    AS tourist_id,
    r.firstName    AS first_name,
    r.lastName     AS last_name,
    r.email        AS email,
    r.country      AS country,
    r.birthDate    AS birth_date,
    r.registrationDate AS registration_date
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/TouristView'),
            'array<struct<touristId:string,firstName:string,lastName:string,email:string,country:string,birthDate:string,registrationDate:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_SQL_HotelView AS
SELECT
    r.hotelId       AS hotel_id,
    r.name          AS name,
    r.starRating    AS star_rating,
    r.city          AS city,
    r.country       AS country,
    r.capacity      AS capacity,
    r.pricePerNight AS price_per_night
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/HotelView'),
            'array<struct<hotelId:string,name:string,starRating:string,city:string,country:string,capacity:string,pricePerNight:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_SQL_BookingView AS
SELECT
    r.bookingId     AS booking_id,
    r.touristId     AS tourist_id,
    r.hotelId       AS hotel_id,
    r.checkInDate   AS check_in_date,
    r.checkOutDate  AS check_out_date,
    r.numGuests     AS num_guests,
    r.totalAmount   AS total_amount,
    r.bookingStatus AS booking_status,
    r.bookingDate   AS booking_date
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-sql-jpa:8090/DSA-SQL-JPAService/rest/tourism/BookingView'),
            'array<struct<bookingId:string,touristId:string,hotelId:string,checkInDate:string,checkOutDate:string,numGuests:string,totalAmount:string,bookingStatus:string,bookingDate:string>>'
        )
    ) AS r
) t;

