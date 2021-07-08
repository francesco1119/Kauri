/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 


DeviceNumber
	,MachineType
	,OsFamilyName
	,Edition
	,.[dbo].[MAP_Toolkit_Results].ConnectionString
	,[Full_Instance_name]
	,ServerName
	,.[dbo].[MAP_Toolkit_Results].InstanceName
	,[Domain/Workgroup]
	,Server_Domain
	,[Size in MB]
	,[Size in GB]
	,CreatedTimestamp
	,SQL_Server_Version
	,CompatibilityLevel
	,Collation
	,DatabaseName
	,DbName
	,ImpactedObjectName
	,ImpactDetail
	,AssessmentName
	,Category
	,ObjectType
	,Title
	,Impact
	,Recommendation
	,MoreInfo
	,[dbo].[dimChangeCategory].ChangeCategory
	,Severity
--INTO PowerBI_Assessment
FROM [FactAssessment]
INNER JOIN [dimCategory] ON [FactAssessment].[Categorykey] = [dimCategory].[Categorykey]
INNER JOIN [dimChangeCategory] ON [FactAssessment].[ChangeCategoryKey] = [dimChangeCategory].[ChangeCategoryKey]
INNER JOIN [dimObjectType] ON [FactAssessment].[ObjectTypeKey] = [dimObjectType].[ObjectTypeKey]
INNER JOIN [dimRules] ON [FactAssessment].[RulesKey] = [dimRules].[RulesKey]
INNER JOIN [dimSeverity] ON [FactAssessment].[Severitykey] = [dimSeverity].[Severitykey]
INNER JOIN [dimSourceCompatibility] ON [FactAssessment].[SourceCompatKey] = [dimSourceCompatibility].[SourceCompatKey]
INNER JOIN [dimTargetCompatibility] ON [FactAssessment].[TargetCompatKey] = [dimTargetCompatibility].[TargetCompatKey]
full  JOIN .[dbo].[MAP_Toolkit_Results] ON ([FactAssessment].[InstanceName] = .[dbo].[MAP_Toolkit_Results].[Full_Instance_name])
	AND ([FactAssessment].[DatabaseName] = .[dbo].[MAP_Toolkit_Results].[DbName])
	--where DatabaseName is NULL
	--group by ConnectionString
	--order by ConnectionString
