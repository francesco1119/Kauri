-- Put here a part of the code you are targeting or even the whole query
DECLARE @Search_for_query NVARCHAR(300) SET @Search_for_query = '%FORMAT(GETDATE(),''hh:mm:ss'')%'
-- Define the maximum time you want the query to run
DECLARE @Time_to_run_in_minutes INT SET @Time_to_run_in_minutes = 1

DECLARE @SPID_older_than smallint
SET @SPID_older_than = (
                                    SELECT TOP 1 
                                    --text,
                                    session_id
                                    --,start_time
                                    FROM sys.dm_exec_requests  
                                    CROSS APPLY sys.dm_exec_sql_text(sql_handle)  
                                    WHERE text LIKE @Search_for_query       
                                    AND text NOT LIKE '%sys.dm_exec_sql_text(sql_handle)%'      -- This will avoid the killing job to kill itself 
                                    AND start_time < DATEADD(MINUTE, -@Time_to_run_in_minutes, GETDATE())            
                                    )

-- SELECT @SPID_older_than                                                           -- Use this for testing

DECLARE @SQL nvarchar(1000)
SET @SQL = 'KILL ' + CAST(@SPID_older_than as varchar(20))
EXEC (@SQL)
