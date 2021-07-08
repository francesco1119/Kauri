
SELECT 
text,
session_id
,start_time
FROM sys.dm_exec_requests  
CROSS APPLY sys.dm_exec_sql_text(sql_handle)  
WHERE text LIKE '%FORMAT(GETDATE(),''hh:mm:ss'')%'		-- Put here a part of the code you are targeting or even the whole query
AND text NOT LIKE '%sys.dm_exec_sql_text(sql_handle)%'			-- This will avoid the killing job to kill itself 
--AND start_time > GETDATE() 

--KILL 78

