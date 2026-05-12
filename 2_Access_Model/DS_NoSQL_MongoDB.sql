-- ============================================================================
-- SparkSQL: DS3 - MongoDB Data Source Views (via MongoDB REST Service)
-- Target: DSA-NoSQL-MongoDBService on port 8093
-- ============================================================================

CREATE OR REPLACE VIEW DS_NoSQL_MongoBookingView AS
SELECT
    r.bookingId      AS booking_id,
    r.bookingDate    AS booking_date,
    r.guestFirstName AS guest_first_name,
    r.guestLastName  AS guest_last_name,
    r.guestEmail     AS guest_email,
    r.guestCountry   AS guest_country,
    r.guestAgeGroup  AS guest_age_group,
    r.destination    AS destination,
    r.travelType     AS travel_type,
    r.startDate      AS start_date,
    r.endDate        AS end_date,
    r.durationDays   AS duration_days,
    r.subtotalEur    AS subtotal_eur,
    r.taxRate        AS tax_rate,
    r.taxAmount      AS tax_amount,
    r.totalEur       AS total_eur,
    r.paymentStatus  AS payment_status,
    r.paymentDate    AS payment_date,
    r.agentId        AS agent_id
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/mongodb/MongoBookingView'),
            'array<struct<bookingId:string,bookingDate:string,guestFirstName:string,guestLastName:string,guestEmail:string,guestCountry:string,guestAgeGroup:string,destination:string,travelType:string,startDate:string,endDate:string,durationDays:string,subtotalEur:string,taxRate:string,taxAmount:string,totalEur:string,paymentStatus:string,paymentDate:string,agentId:string>>'
        )
    ) AS r
) t;

CREATE OR REPLACE VIEW DS_NoSQL_CurrencyView AS
SELECT
    r.currencyCode   AS currency_code,
    r.currencyName   AS currency_name,
    r.exchangeRate   AS exchange_rate,
    r.region         AS region,
    r.symbol         AS symbol,
    r.baseCurrency   AS base_currency,
    r.extractionDate AS extraction_date
FROM (
    SELECT explode(
        from_json(
            java_method('org.spark.service.rest.QueryRESTDataService', 'getRESTDataDocument',
                'http://dsa-nosql-mongodb:8093/DSA-NoSQL-MongoDBService/rest/mongodb/CurrencyView'),
            'array<struct<currencyCode:string,currencyName:string,exchangeRate:string,region:string,symbol:string,baseCurrency:string,extractionDate:string>>'
        )
    ) AS r
) t;
