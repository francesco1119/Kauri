/*
https://techcommunity.microsoft.com/t5/azure-database-support-blog/lesson-learned-413-perfstat-performance-stats-collection-for/ba-p/3893763
*/

PRINT '-------------------------------------------------------------------------------'
PRINT '-- All results are for database: '+ DB_NAME() +' ,server: '+@@SERVERNAME+' --'
PRINT '-------------------------------------------------------------------------------'

SET NOCOUNT ON
SET ANSI_WARNINGS OFF
GO

PRINT '-- STATS_DATE and rowmodctr for '+ DB_NAME() +'.sysindexes --'
select db_id() as dbid, 
CAST(NULL as int) as rowcnt, 
CAST(NULL as int) as row_mods,
CAST(NULL as float) as pct_mod,
o.name as objname,
case when (s. stats_id>2 AND s.auto_created=1) then 'AUTOSTATS'
	 when (s. stats_id>2 AND s.auto_created=0) then 'STATS'
    else 'INDEX'
end as type,
case when s.stats_id >2 then s.name
else i.name 
end as idxname, 
case when s.stats_id >2 then s.stats_id
else i.index_id 
end as indid, 
case when s.stats_id >2 then STATS_DATE(o.object_id, s.stats_id)
else STATS_DATE(o.object_id, i.index_id) 
end as stats_updated, 
 s.no_recompute as norecompute, 
 o.object_id as objid ,  0 as status 
from sys.objects o 
join sys.stats s with (nolock) on s.object_id=o.object_id 
left outer join sys.indexes i with (nolock) on i.object_id= s.object_id AND s.stats_id in (1,2)
WHERE o.type = 'U'
order by objid

DECLARE @runtime datetime 
SET @runtime = GETDATE()
PRINT ''
PRINT '==============================================================================================='
PRINT 'Missing Indexes: '
PRINT 'The "improvement_measure" column is an indicator of the (estimated) improvement that might '
PRINT 'be seen if the index was created.  This is a unitless number, and has meaning only relative '
PRINT 'the same number for other indexes.  The measure is a combination of the avg_total_user_cost, '
PRINT 'avg_user_impact, user_seeks, and user_scans columns in sys.dm_db_missing_index_group_stats.'
PRINT ''
PRINT '-- Missing Indexes --'
SELECT CONVERT (varchar, @runtime, 126) AS runtime, 
  mig.index_group_handle, mid.index_handle, 
  CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure, 
  'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
  + ' ON ' + mid.statement 
  + ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
  + ')' 
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement, 
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

print '-- query and plan hash capture --'

print '-- top 10 CPU by query_hash --'
select getdate() as runtime, *  --into tbl_QueryHashByCPU
from
(
SELECT TOP 10 query_hash, COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	 sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',	 
    max(REPLACE(REPLACE (REPLACE (SUBSTRING (CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (st.[text]) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_worker_time) DESC
) t
go

print '-- top 10 logical reads by query_hash --'
select getdate() as runtime, *  --into tbl_QueryHashByLogicalReads
from
(
SELECT TOP 10 query_hash, 
	COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE(REPLACE (REPLACE (SUBSTRING (CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (st.[text]) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_logical_reads) DESC
) t
go

print '-- top 10 elapsed time by query_hash --'
select getdate() as runtime, * -- into tbl_QueryHashByElapsedTime
from
(
SELECT TOP 10 query_hash, 
	sum(execution_count) as 'execution_count', 
	COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE(REPLACE (REPLACE (SUBSTRING (CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (st.[text]) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_elapsed_time) DESC
) t
go

print '-- top 10 CPU by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, 
COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (REPLACE (SUBSTRING (CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN ( st.[text])
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_worker_time) DESC;
go

print '-- top 10 logical reads by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE( REPLACE (REPLACE (SUBSTRING (CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (st.[text]) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_logical_reads) DESC;
go

print '-- top 10 elapsed time  by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE( REPLACE (REPLACE (SUBSTRING ( CONVERT(nvarchar(4000),st.[text]), qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (st.[text]) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '), CHAR(09), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_elapsed_time) DESC;
go

RAISERROR (' ', 0, 1) WITH NOWAIT
PRINT '-- sys.dm_db_resource_stats for '+ DB_NAME() +' --'
SELECT 
end_time,
CONVERT(NUMERIC(10,2),avg_cpu_percent) as 'avg_cpu_percent',    
CONVERT(NUMERIC(10,2),avg_data_io_percent) as 'avg_data_io_percent',    
CONVERT(NUMERIC(10,2),avg_log_write_percent) as 'avg_log_write_percent',    
CONVERT(NUMERIC(10,2),avg_memory_usage_percent) as 'avg_memory_usage_percent'
FROM sys.dm_db_resource_stats 
order by end_time desc

SET NOCOUNT OFF
SET ANSI_WARNINGS ON
GO
