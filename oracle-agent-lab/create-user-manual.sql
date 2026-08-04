-- Create monitoring user for Oracle integration
-- Connect to the default PDB (FREEPDB1)

-- Drop user if exists (cleanup)
DECLARE
  user_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'ELASTIC_MONITOR';
  IF user_exists > 0 THEN
    EXECUTE IMMEDIATE 'DROP USER elastic_monitor CASCADE';
  END IF;
END;
/

-- Create the monitoring user
CREATE USER elastic_monitor IDENTIFIED BY ElasticMon123
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

-- Grant necessary system privileges
GRANT CREATE SESSION TO elastic_monitor;
GRANT SELECT_CATALOG_ROLE TO elastic_monitor;

-- Grant SELECT on required views for tablespace metrics
GRANT SELECT ON SYS.DBA_DATA_FILES TO elastic_monitor;
GRANT SELECT ON SYS.DBA_TEMP_FILES TO elastic_monitor;
GRANT SELECT ON DBA_FREE_SPACE TO elastic_monitor;
GRANT SELECT ON DBA_TABLESPACE_USAGE_METRICS TO elastic_monitor;
GRANT SELECT ON DBA_TABLESPACES TO elastic_monitor;
GRANT SELECT ON DBA_TEMP_FREE_SPACE TO elastic_monitor;

-- Grant SELECT on other views used by Oracle integration
GRANT SELECT ON V_$SYSMETRIC TO elastic_monitor;
GRANT SELECT ON V_$SGASTAT TO elastic_monitor;
GRANT SELECT ON V_$PGASTAT TO elastic_monitor;
GRANT SELECT ON V_$SYSSTAT TO elastic_monitor;
GRANT SELECT ON V_$BUFFER_POOL_STATISTICS TO elastic_monitor;
GRANT SELECT ON V_$SESSTAT TO elastic_monitor;
GRANT SELECT ON V_$LIBRARYCACHE TO elastic_monitor;
GRANT SELECT ON DBA_JOBS TO elastic_monitor;
GRANT SELECT ON GV_$SESSION TO elastic_monitor;
GRANT SELECT ON V_$SYSTEM_WAIT_CLASS TO elastic_monitor;
GRANT SELECT ON V_$INSTANCE TO elastic_monitor;

-- Create some test tablespaces to ensure data is available
DECLARE
  tbs_exists NUMBER;
BEGIN
  -- Check if tablespace exists
  SELECT COUNT(*) INTO tbs_exists FROM dba_tablespaces WHERE tablespace_name = 'TEST_DATA';
  IF tbs_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLESPACE test_data DATAFILE SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M';
  END IF;
END;
/

-- Output confirmation
SELECT 'User elastic_monitor created successfully!' AS status FROM dual;
SELECT 'Grants applied' AS status FROM dual;
SELECT COUNT(*) AS tablespace_count FROM dba_tablespaces;
