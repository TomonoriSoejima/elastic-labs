-- Tablespace Usage Monitoring Query
-- Shows tablespace size, usage, and free space information

SET LINESIZE 200
SET PAGESIZE 100
COLUMN tablespace_name FORMAT A30
COLUMN total_mb FORMAT 999,999,999.99
COLUMN used_mb FORMAT 999,999,999.99
COLUMN free_mb FORMAT 999,999,999.99
COLUMN pct_used FORMAT 999.99

SELECT 
    df.tablespace_name,
    ROUND(df.total_space / 1024 / 1024, 2) AS total_mb,
    ROUND((df.total_space - fs.free_space) / 1024 / 1024, 2) AS used_mb,
    ROUND(fs.free_space / 1024 / 1024, 2) AS free_mb,
    ROUND(((df.total_space - fs.free_space) / df.total_space) * 100, 2) AS pct_used
FROM 
    (SELECT 
         tablespace_name,
         SUM(bytes) AS total_space
     FROM dba_data_files
     GROUP BY tablespace_name) df,
    (SELECT 
         tablespace_name,
         SUM(bytes) AS free_space
     FROM dba_free_space
     GROUP BY tablespace_name) fs
WHERE 
    df.tablespace_name = fs.tablespace_name
ORDER BY 
    pct_used DESC;

PROMPT
PROMPT Tablespace Details by File:
PROMPT

COLUMN file_name FORMAT A60
COLUMN size_mb FORMAT 999,999.99
COLUMN autoextensible FORMAT A5

SELECT 
    tablespace_name,
    file_name,
    ROUND(bytes / 1024 / 1024, 2) AS size_mb,
    ROUND(maxbytes / 1024 / 1024, 2) AS max_mb,
    autoextensible
FROM 
    dba_data_files
ORDER BY 
    tablespace_name, file_name;
