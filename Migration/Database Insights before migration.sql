
SELECT
	@@servername AS 'Server Name'
   ,d.name AS [Database_Name]
   ,d.compatibility_level
   ,CASE
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '8%' THEN 'SQL2000'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '9%' THEN 'SQL2005'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '10.0%' THEN 'SQL2008'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '10.5%' THEN 'SQL2008 R2'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '11%' THEN 'SQL2012'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '12%' THEN 'SQL2014'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '13%' THEN 'SQL2016'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '14%' THEN 'SQL2017'
		WHEN CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')) LIKE '15%' THEN 'SQL2019'
		ELSE 'unknown'
	END AS SQL_Server_Version,
   d.collation_name
   ,cast((SUM(CAST(mf.size AS DECIMAL(10,2))) * 8 / 1024) / 1024 AS DECIMAL(18,2))  AS Size_GBs
FROM sys.master_files mf
INNER JOIN sys.databases d
	ON d.database_id = mf.database_id
WHERE d.database_id > 4 -- Skip system databases
GROUP BY d.name
		,d.compatibility_level
		,d.collation_name
ORDER BY d.name

