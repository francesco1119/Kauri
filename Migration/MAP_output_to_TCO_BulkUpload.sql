/****** Script for SelectTopNRows command from SSMS  ******/
SELECT DbName AS [Database Name],
	'' AS [DB Type],
	Edition AS [License],
	CASE 
		WHEN [MachineType] = 'Virtual'
			THEN 'Virtual Machines'
		WHEN [MachineType] = 'Physical'
			THEN 'Physical Machines'
		ELSE NULL
		END AS [Environment],
	[OsFamilyName] AS OS,
	CurrentOperatingSystem AS [OS License],
	'' AS [Servers or VMs],
	NumberOfProcessors AS [Procs per Server],
	NumberOfCores AS [Cores per Proc],
	NumberOfLogicalProcessors AS [Cores],
	'' AS [Virtualization],
	((cast(SystemMemory AS FLOAT) * 1.0 / 1024)) AS [RAM (GB)],
	'' AS [Optimized by],
	CASE 
		WHEN [OsFamilyName] = 'Windows Server 2003'
			THEN 'YES'
		WHEN [OsFamilyName] = 'Windows Server 2008'
			THEN 'YES'
		WHEN [OsFamilyName] = 'Windows Server 2008 R2'
			THEN 'YES'
		WHEN [OsFamilyName] = 'Windows Server 2012'
			THEN 'NO'
		WHEN [OsFamilyName] = 'Windows Server 2012 R2'
			THEN 'NO'
		WHEN [OsFamilyName] = 'Windows Server 2019'
			THEN 'NO'
		ELSE NULL
		END AS [SQL Server 2K8],
	'' AS [High Availability] FROM [SqlServer_Inventory].[DataBaseProperties] LEFT JOIN [SqlServer_Inventory].[DataBaseServerProperties] ON [SqlServer_Inventory].[DataBaseProperties].[ServerName] = [SqlServer_Inventory].[DataBaseServerProperties].[ServerName] LEFT JOIN [AllDevices_Assessment].[HardwareInventoryCore] ON [SqlServer_Inventory].[DataBaseProperties].[DeviceNumber] = [AllDevices_Assessment].[HardwareInventoryCore].[DeviceNumber] LEFT JOIN [AllDevices_Assessment].[HardwareInventoryEx] ON [SqlServer_Inventory].[DataBaseProperties].[DeviceNumber] = [AllDevices_Assessment].[HardwareInventoryEx].[DeviceNumber] WHERE DbName NOT IN (
		'master',
		'model',
		'tempdb',
		'msdb'
		)
	AND OsFamilyName LIKE 'Windows Ser%'