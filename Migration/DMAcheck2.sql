/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
	--[SqlServer_Inventory].[DataBaseProperties].[DeviceNumber]
	--	,[MachineType]
	--	,OsFamilyName
	--	,[Edition]
	--	,LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1) AS ServerName
	--	,[Domain/Workgroup]
	CONCAT (
		LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
		,'.'
		,[Domain/Workgroup]
		) AS Server_Domain
	,[SqlServer_Inventory].[DataBaseServerProperties].InstanceName
	--,[DbName]
	--,[Size]
	--,convert(NUMERIC(10, 2), substring([Size], 1, (len([Size]) - 3))) AS [Size in MB]
	--,CAST(convert(NUMERIC(10, 2), substring([Size], 1, (len([Size]) - 3))) / 1024 AS NUMERIC(10, 2)) AS [Size in GB]
	--,[CreatedTimestamp]
	--,CASE 
	--	WHEN ProductVersion LIKE '8%'
	--		THEN 'SQL2000'
	--	WHEN ProductVersion LIKE '9%'
	--		THEN 'SQL2005'
	--	WHEN ProductVersion LIKE '10.0%'
	--		THEN 'SQL2008'
	--	WHEN ProductVersion LIKE '10.5%'
	--		THEN 'SQL2008 R2'
	--	WHEN ProductVersion LIKE '11%'
	--		THEN 'SQL2012'
	--	WHEN ProductVersion LIKE '12%'
	--		THEN 'SQL2014'
	--	WHEN ProductVersion LIKE '13%'
	--		THEN 'SQL2016'
	--	WHEN ProductVersion LIKE '14%'
	--		THEN 'SQL2017'
	--	WHEN ProductVersion LIKE '15%'
	--		THEN 'SQL2019'
	--	ELSE NULL
	--	END AS SQL_Server_Version
	--,[CompatibilityLevel]
	--,right([Status], charindex('=', reverse([Status])) - 1) AS [Collation]
	,CASE 
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName = 'MSSQLSERVER'
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					)
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName != 'MSSQLSERVER'
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					,'\'
					,[SqlServer_Inventory].[DataBaseServerProperties].InstanceName
					)
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName IS NULL
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					)
		ELSE 'error'
		END AS Complete_Name
	,CONCAT (
		'<AssessmentDatabase>Server='
		,CASE 
			WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName = 'MSSQLSERVER'
				THEN CONCAT (
						LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
						,'.'
						,[Domain/Workgroup]
						)
			WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName != 'MSSQLSERVER'
				THEN CONCAT (
						LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
						,'.'
						,[Domain/Workgroup]
						,'\'
						,[SqlServer_Inventory].[DataBaseServerProperties].InstanceName
						)
			WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName IS NULL
				THEN CONCAT (
						LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
						,'.'
						,[Domain/Workgroup]
						)
			ELSE 'error'
			END
		,';Integrated Security=true</AssessmentDatabase>'
		) AS Copy_Paste_This
FROM [SqlServer_Inventory].[DataBaseProperties]
LEFT JOIN [SqlServer_Inventory].[DataBaseServerProperties] ON [SqlServer_Inventory].[DataBaseProperties].[ServerName] = [SqlServer_Inventory].[DataBaseServerProperties].[ServerName]
LEFT JOIN [AllDevices_Assessment].[HardwareInventoryCore] ON [SqlServer_Inventory].[DataBaseProperties].[DeviceNumber] = [AllDevices_Assessment].[HardwareInventoryCore].[DeviceNumber]
LEFT JOIN [AllDevices_Assessment].[HardwareInventoryEx] ON [SqlServer_Inventory].[DataBaseProperties].[DeviceNumber] = [AllDevices_Assessment].[HardwareInventoryEx].[DeviceNumber]
WHERE 

DbName NOT IN (
		'master'
		,'model'
		,'tempdb'
		,'msdb'
		)
		and

OsFamilyName LIKE 'Windows Ser%'
and concat(LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1),'.',[Domain/Workgroup]) like '%ExpressVending.local'
GROUP BY CONCAT (
		LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
		,'.'
		,[Domain/Workgroup]
		)
	,[SqlServer_Inventory].[DataBaseServerProperties].InstanceName
	,CASE 
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName = 'MSSQLSERVER'
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					)
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName != 'MSSQLSERVER'
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					,'\'
					,[SqlServer_Inventory].[DataBaseServerProperties].InstanceName
					)
		WHEN [SqlServer_Inventory].[DataBaseServerProperties].InstanceName IS NULL
			THEN CONCAT (
					LEFT([ComputerName] + '.', CHARINDEX('.', [ComputerName] + '.') - 1)
					,'.'
					,[Domain/Workgroup]
					)
		ELSE 'error'
		END
ORDER BY 1
