-- Find where objects were created
SET PAGESIZE 100 LINESIZE 200
COLUMN owner FORMAT A20
COLUMN table_name FORMAT A30

SELECT owner, table_name 
FROM dba_tables 
WHERE table_name LIKE 'FACT_%' 
   OR table_name LIKE 'DIM_%'
   OR table_name LIKE 'HOTELS_%'
   OR table_name LIKE 'BOOKINGS_%'
ORDER BY owner, table_name;

EXIT;
