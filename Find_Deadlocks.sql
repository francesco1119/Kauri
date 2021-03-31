https://dba.stackexchange.com/questions/281379/catch-deadlock-events-in-a-background-job

--Get xml_deadlock_report events from system_health session file target
WITH
      --get trace folder path and append session name with wildcard (assumes base file name is same as session name)
      all_trace_files AS (
        SELECT path + '\system_health*.xel' AS FileNamePattern
        FROM sys.dm_os_server_diagnostics_log_configurations
        )
      --get xml_deadlock_report events from all system_health trace files
    , deadlock_reports AS (
        SELECT CAST(event_data AS xml) AS deadlock_report_xml
        FROM all_trace_files
        CROSS APPLY sys.fn_xe_file_target_read_file ( FileNamePattern, NULL, NULL, NULL) AS trace_records
        WHERE trace_records.object_name like 'xml_deadlock_report'
    )
SELECT TOP 10
      deadlock_report_xml.value('(/event/@timestamp)[1]', 'datetime2') AS UtcTimestamp
    , deadlock_report_xml AS DeadlockReportXml
FROM deadlock_reports;
