/*
https://raresql.com/2022/11/01/azure-data-studio-extensions-query-history/
Find which queries have been executed
*/

SELECT last_execution_time
     , text 
FROM sys.dm_exec_query_stats stats 
CROSS APPLY sys.dm_exec_sql_text(sql_handle)  
ORDER BY
       last_execution_time DESC
GO
--OUTPUT