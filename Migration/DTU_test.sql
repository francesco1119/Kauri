WITH DB_CPU_Stats
AS
( SELECT
		DatabaseID
	   ,ISNULL(DB_NAME(DatabaseID), CASE DatabaseID
			WHEN 32767 THEN 'Internal ResourceDB'
			ELSE CONVERT(VARCHAR(255), DatabaseID)
		END) AS [DatabaseName]
	   ,SUM(total_worker_time) AS [CPU Time Ms]
	   ,SUM(total_logical_reads) AS [Logical Reads]
	   ,SUM(total_logical_writes) AS [Logical Writes]
	   ,SUM(total_logical_reads + total_logical_writes) AS [Logical IO]
	   ,SUM(total_physical_reads) AS [Physical Reads]
	   ,SUM(total_elapsed_time) AS [Duration MicroSec]
	   ,SUM(total_clr_time) AS [CLR Time MicroSec]
	   ,SUM(total_rows) AS [Rows Returned]
	   ,SUM(execution_count) AS [Execution Count]
	   ,COUNT(*) 'Plan Count'

	FROM sys.dm_exec_query_stats AS qs
	CROSS APPLY (SELECT
			CONVERT(INT, value) AS [DatabaseID]
		FROM sys.dm_exec_plan_attributes(qs.plan_handle)
		WHERE attribute = N'dbid') AS F_DB
	GROUP BY DatabaseID)
SELECT
	ROW_NUMBER() OVER (ORDER BY [CPU Time Ms] DESC) AS [Rank CPU]
   ,DatabaseName
   ,[Logical Reads]
   ,[Logical Writes]
   ,[CPU Time Ms]
   ,[CPU Time Ms] / 1000 [CPU Time Sec]
   ,[Duration MicroSec]
   ,[Duration MicroSec] / 1000000 [Duration Sec]
FROM DB_CPU_Stats
ORDER BY [Rank CPU]
OPTION (RECOMPILE);