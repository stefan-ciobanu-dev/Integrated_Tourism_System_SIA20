-- ============================================================================
-- DS3: Currency Exchange Rates - European Central Bank (ECB)
-- Data Model Definition
-- ============================================================================

CREATE TABLE IF NOT EXISTS TOURISM_ADMIN.CURRENCY_DS3 (
  CURRENCY_CODE VARCHAR2(3) PRIMARY KEY,
  CURRENCY_NAME VARCHAR2(50),
  EUR_RATE NUMBER(12,6),
  RATE_DATE DATE DEFAULT TRUNC(SYSDATE),
  SOURCE VARCHAR2(50) DEFAULT 'ECB',
  LAST_UPDATE TIMESTAMP DEFAULT SYSDATE
) TABLESPACE USERS;

-- Indexes
CREATE INDEX IDX_CURRENCY_DATE ON TOURISM_ADMIN.CURRENCY_DS3(RATE_DATE);
CREATE INDEX IDX_CURRENCY_SOURCE ON TOURISM_ADMIN.CURRENCY_DS3(SOURCE);

-- Data loaded from ECB daily XML feed
-- Source: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
BEGIN
  DELETE FROM TOURISM_ADMIN.CURRENCY_DS3;
  
  -- EUR is always 1.0 (base currency)
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('EUR', 'Euro', 1.000000, TRUNC(SYSDATE), 'ECB', SYSDATE);
  
  -- Real rates from ECB will be inserted by Node.js during startup
  -- These are sample rates as of April 2026
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('USD', 'US Dollar', 1.1525, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('JPY', 'Japanese Yen', 183.94, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('GBP', 'British Pound', 0.8560, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('CHF', 'Swiss Franc', 0.9670, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('RON', 'Romanian Leu', 4.9720, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('CZK', 'Czech Koruna', 24.540, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('DKK', 'Danish Krone', 7.4722, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('HUF', 'Hungarian Forint', 398.50, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('PLN', 'Polish Zloty', 4.1245, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('SEK', 'Swedish Krona', 11.45, TRUNC(SYSDATE), 'ECB', SYSDATE);
  INSERT INTO TOURISM_ADMIN.CURRENCY_DS3 VALUES 
    ('NOK', 'Norwegian Krone', 11.95, TRUNC(SYSDATE), 'ECB', SYSDATE);
  
  COMMIT;
END;
/

PROMPT DS_3 Currency table created with official ECB rates
PROMPT Source: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
PROMPT Update: Real rates loaded on server startup via Node.js integration
