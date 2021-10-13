-- From: https://tidbytez.com/2017/05/22/how-to-identify-and-remove-unused-tables-in-sql-server-with-t-sql/comment-page-1/?unapproved=3120&moderation-hash=d7e5ba47318ed39f5b5c46e1fbc64072#comment-3120

SET NOCOUNT ON

DECLARE @Database TABLE ([DbName] [sysname])
DECLARE @DbName AS [sysname]
DECLARE @Sql AS [varchar] (max)

IF OBJECT_ID('tempdb..#TableStats', 'U') IS NOT NULL
	DROP TABLE #TableStats

IF OBJECT_ID('tempdb..#IndexStats', 'U') IS NOT NULL
	DROP TABLE #IndexStats

IF OBJECT_ID('tempdb..#TableUsageStats', 'U') IS NOT NULL
	DROP TABLE #TableUsageStats

IF OBJECT_ID('tempdb..#TableSizeStats', 'U') IS NOT NULL
	DROP TABLE #TableSizeStats

CREATE TABLE #TableStats (
	[DbName] [sysname]
	,[SchemaName] [sysname]
	,[ObjectId] [bigint]
	,[TableName] [sysname]
	,[ModifiedDate] [datetime]
	);

CREATE TABLE #IndexStats (
	[DbName] [sysname]
	,[ObjectId] [bigint]
	,[HasIndex] [bit]
	);

CREATE TABLE #TableSizeStats (
	[DbName] [varchar](255) NULL
	,[SchemaName] [varchar](255) NULL
	,[ObjectId] [bigint]
	,[TableName] [varchar](255) NULL
	,[RowCount] [bigint] NULL
	,[AvailableSpacePercentage] [numeric](6, 2) NULL
	,[UnusedSpaceGb] [numeric](10, 3) NULL
	,[UsedSpaceGb] [numeric](10, 3) NULL
	,[TotalSpaceGb] [numeric](10, 3) NULL
	,[UnusedSpaceMb] [numeric](13, 3) NULL
	,[UsedSpaceMb] [numeric](13, 3) NULL
	,[TotalSpaceMb] [numeric](13, 3) NULL
	,[UnusedSpaceKb] [bigint] NULL
	,[UsedSpaceKb] [bigint] NULL
	,[TotalSpaceKb] [bigint] NULL
	)

CREATE TABLE #TableUsageStats (
	[DbName] [sysname]
	,[ObjectId] [bigint]
	,[TableName] [nvarchar](128) NULL
	,[LastUserUpdate] [datetime] NULL
	,[LastUserSeek] [datetime] NULL
	,[LastUserScan] [datetime] NULL
	,[LastUserLookup] [datetime] NULL
	,[UserUpdateCount] [bigint] NOT NULL
	,[UserSeekCount] [bigint] NOT NULL
	,[UserScanCount] [bigint] NOT NULL
	,[UserLookupCount] [bigint] NOT NULL
	);

SET @DbName = '';

INSERT INTO @Database (DbName)
SELECT NAME
FROM sys.databases 
WHERE NAME NOT IN (
		'tempdb'
		,'master'
		,'mode'
		,'model'
		)
AND state_desc = 'ONLINE'
ORDER BY NAME ASC;

WHILE @DbName IS NOT NULL
BEGIN
	SET @DbName = (
			SELECT MIN(DbName)
			FROM @Database
			WHERE DbName > @DbName
			);
	SET @Sql = '
INSERT INTO #TableStats (
	DbName
	,schemaName
	,ObjectId
	,TableName
	,ModifiedDate
	)
SELECT DbName
	,SchemaName
	,ObjectId
	,TableName
	,ModifiedDate
FROM (
SELECT DISTINCT ' + '''' + @DbName + '''' + ' AS DbName
	,s.NAME AS SchemaName
	,t.object_id AS ObjectId
	,t.NAME AS TableName
	,t.modify_date AS ModifiedDate
FROM ' + QUOTENAME(@DbName) + '.sys.tables AS t
INNER JOIN ' + QUOTENAME(@DbName) + '.sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN ' + QUOTENAME(@DbName) + '.sys.extended_properties AS ep ON ep.major_id = t.[object_id] /*Exclude System Tables*/
WHERE t.NAME IS NOT NULL
	AND s.NAME IS NOT NULL
	AND (ep.[name] IS NULL OR ep.[name] <> ''microsoft_database_tools_support'')
	) AS rd
WHERE rd.SchemaName IS NOT NULL
ORDER BY DbName ASC
	,TableName ASC;
'

	EXEC (@Sql)

	SELECT @Sql = '
INSERT INTO #IndexStats (
	DbName
	,ObjectId
	,HasIndex
	)
SELECT ' + '''' + @DbName + '''' + ' AS DbName
	,OBJECT_ID AS ObjectId
	,IndexCheck AS HasIndex
FROM (
	SELECT DISTINCT OBJECT_ID
		,CASE 
			WHEN (
					[TYPE] > 0
					AND is_disabled = 0
					)
				THEN 1
			ELSE 0
			END AS IndexCheck
	FROM ' + QUOTENAME(@DbName) + '.sys.indexes
	) AS rd
WHERE rd.IndexCheck = 1
'

	EXEC (@Sql)

	SET @Sql = 
		'
INSERT INTO #TableSizeStats (
	[DbName]
	,[SchemaName]
	,[ObjectId]
	,[TableName]
	,[RowCount]
	,[AvailableSpacePercentage]
	,[UnusedSpaceGb]
	,[UsedSpaceGb]
	,[TotalSpaceGb]
	,[UnusedSpaceMb]
	,[UsedSpaceMb]
	,[TotalSpaceMb]
	,[UnusedSpaceKb]
	,[UsedSpaceKb]
	,[TotalSpaceKb]
	)
SELECT DISTINCT rd.[DbName]
	,rd.[SchemaName]
	,rd.[ObjectId]
	,rd.[TableName]
	,rd.[RowCount]
	,CASE 
		WHEN TotalSpaceKb > 0
			THEN ((UnusedSpaceKb / TotalSpaceKb) * 100)
		ELSE 0
		END AS AvailableSpacePercentage
	,CONVERT(NUMERIC(10, 3), (rd.[UnusedSpaceKb] / 1024.) / 1024.) AS UnusedSpaceGb
	,CONVERT(NUMERIC(10, 3), (rd.[UsedSpaceKb] / 1024.) / 1024.) AS UsedSpaceGb
	,CONVERT(NUMERIC(10, 3), (rd.[TotalSpaceKb] / 1024.) / 1024.) AS TotalSpaceGb
	,CONVERT(NUMERIC(13, 3), (rd.[UnusedSpaceKb] / 1024.)) AS UnusedSpaceMb
	,CONVERT(NUMERIC(13, 3), (rd.[UsedSpaceKb] / 1024.)) AS UsedSpaceMb
	,CONVERT(NUMERIC(13, 3), (rd.[TotalSpaceKb] / 1024.)) AS TotalSpaceMb
	,rd.[UnusedSpaceKb]
	,rd.[UsedSpaceKb]
	,rd.[TotalSpaceKb]
FROM (
	SELECT ' 
		+ '''' + @DbName + '''' + ' AS DbName
		,t.Object_id AS ObjectId
		,s.[name] AS [SchemaName]
		,t.[name] AS [TableName]
		,p.[rows] AS [RowCount]
		,SUM(a.[used_pages]) * 8 AS [UsedSpaceKb]
		,(SUM(a.[total_pages]) - SUM(a.[used_pages])) * 8 AS [UnusedSpaceKb]
		,SUM(a.[total_pages]) * 8 AS [TotalSpaceKb]
	FROM ' + QUOTENAME(@DbName) + '.sys.tables AS t
	INNER JOIN ' + QUOTENAME(@DbName) + '.sys.schemas AS s ON t.schema_id = s.schema_id
	INNER JOIN ' + QUOTENAME(@DbName) + '.sys.indexes AS i ON t.OBJECT_ID = i.object_id
	INNER JOIN ' + QUOTENAME(@DbName) + '.sys.partitions AS p ON i.object_id = p.OBJECT_ID
		AND i.[index_id] = p.[index_id]
	INNER JOIN ' + QUOTENAME(@DbName) + '.sys.allocation_units a ON p.[partition_id] = a.[container_id]
	WHERE t.[is_ms_shipped] = 0
		AND i.OBJECT_ID > 255
	GROUP BY s.[name]
		,t.[name]
		,t.[object_id]
		,p.[rows]
	) AS rd
ORDER BY DbName ASC
	,SchemaName ASC
	,TableName ASC;
'

	EXEC (@Sql)

	SET @Sql = '
INSERT INTO #TableUsageStats (
	[DbName]
	,[ObjectId]
	,[TableName]
	,[LastUserUpdate]
	,[LastUserSeek]
	,[LastUserScan]
	,[LastUserLookup]
	,[UserUpdateCount]
	,[UserSeekCount]
	,[UserScanCount]
	,[UserLookupCount]
	)
SELECT DbName
	,ObjectId
	,TableName
	,LastUserUpdate
	,LastUserSeek
	,LastUserScan
	,LastUserLookup
	,UserUpdateCount
	,UserSeekCount
	,UserScanCount
	,UserLookupCount
FROM (
	SELECT DISTINCT ROW_NUMBER() OVER (
			PARTITION BY ius.Object_Id ORDER BY last_user_update DESC
			) AS RN
		,' + '''' + @DbName + '''' + ' AS DbName
		,ius.OBJECT_ID AS ObjectId
		,o.NAME AS TableName
		,ius.last_user_update AS LastUserUpdate
		,ius.last_user_seek AS LastUserSeek
		,ius.last_user_scan AS LastUserScan
		,ius.last_user_lookup AS LastUserLookup
		,ius.user_updates AS UserUpdateCount
		,ius.user_seeks AS UserSeekCount
		,ius.user_scans AS UserScanCount
		,ius.user_lookups AS UserLookupCount
	FROM ' + QUOTENAME(@DbName) + 
		'.sys.dm_db_index_usage_stats AS ius
	INNER JOIN ' + QUOTENAME(@DbName) + '.sys.objects AS o ON ius.OBJECT_ID = o.OBJECT_ID
		AND o.NAME IS NOT NULL
	) AS rd
WHERE rd.RN = 1
ORDER BY rd.DbName ASC
	,rd.TableName ASC
	,rd.LastUserUpdate DESC
	,rd.LastUserSeek DESC
	,rd.LastUserScan DESC
	,rd.LastUserLookup DESC;
'

	EXEC (@Sql)
END;
GO

SELECT DISTINCT ROW_NUMBER() OVER (
		ORDER BY ts.[DbName] ASC
			,ts.[SchemaName] ASC
			,ts.[TableName] ASC
		) AS Row
	,ts.[DbName]
	,ts.[SchemaName]
	,ts.[TableName]
	,'' AS Action --Rename, keep etc.
	,'' AS Comments
	,'' AS Renamed --boolean flag
	,'' AS RenamedDate 
	,i.[HasIndex] --Tables without an index are heaps
	,tss.[TotalSpaceMb] AS TableSizeInMb
	,ts.[ModifiedDate]
	,tus.[LastUserUpdate]
	,tus.[LastUserSeek]
	,tus.[LastUserScan]
	,tus.[LastUserLookup]
	,tus.[UserUpdateCount]
	,tus.[UserSeekCount]
	,tus.[UserScanCount]
	,tus.[UserLookupCount]
	,tss.[AvailableSpacePercentage]
	,tss.[UnusedSpaceGb]
	,tss.[UsedSpaceGb]
	,tss.[TotalSpaceGb]
	,tss.[UnusedSpaceMb]
	,tss.[UsedSpaceMb]
	,tss.[TotalSpaceMb]
	,tss.[UnusedSpaceKb]
	,tss.[UsedSpaceKb]
	,tss.[TotalSpaceKb]
	,'USE ' + QUOTENAME(ts.[DbName]) + '; EXEC sp_rename ' + '''' + ts.[SchemaName] + '.' + ts.[TableName] + '''' + ', ' + '''' + '_DELETE_' + ts.[TableName] + '''' + ';' AS RenameForDeletion
	,'USE ' + QUOTENAME(ts.[DbName]) + '; EXEC sp_rename ' + '''' + ts.[SchemaName] + '.' + '_DELETE_' + ts.[TableName] + '''' + ', ' + '''' + ts.[TableName] + '''' + ';' AS RestoreOriginalName
	,'USE ' + QUOTENAME(ts.[DbName]) + '; DROP TABLE ' + QUOTENAME(ts.[SchemaName]) + '.' + '[' + '_DELETE_' + ts.[TableName] + ']' + ';' AS 'DropTable'
	,'' AS DroppedDate
FROM #TableStats AS ts
LEFT JOIN #TableSizeStats AS tss ON ts.ObjectId = tss.ObjectId
	AND tss.DbName = ts.DbName
LEFT JOIN #IndexStats AS i ON ts.ObjectId = i.ObjectId
	AND i.DbName = ts.DbName
LEFT JOIN #TableUsageStats AS tus ON ts.ObjectId = tus.ObjectId
	AND tus.DbName = ts.DbName
ORDER BY ts.[DbName] ASC
	,ts.[SchemaName] ASC
	,ts.[TableName] ASC

	-- REF: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-usage-stats-transact-sql
