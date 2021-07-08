/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [DeviceNumber]
      ,[Uid]
      ,[Clustered]
      ,[CreateCollectorId]
      ,[CreateDatetime]
      ,[DnsHostName]
      ,[Instanceid]
      ,[InstanceName]
	  ,CASE sqlservicetype            
   WHEN 1 THEN 'Database'            
   WHEN 2 THEN 'Agent Service'            
   WHEN 3 THEN 'Full Text Engine'            
   WHEN 4 THEN 'Integration Services'            
   WHEN 5 THEN 'Analysis Services  (OLAP I believe)'            
   WHEN 6 THEN 'Reporting Services'
   WHEN 101 THEN 'Master Data Services' 
   WHEN 6 THEN 'Data Quality Services' 
   ELSE CAST(sqlservicetype AS NVARCHAR(20))       END                   AS Component
      ,[Iswow64]
      ,[Language]
      ,[Servicename]
      ,[Sku]
      ,[Skuname]
      ,[Splevel]
      ,[Sqlservicetype]
      ,[UpdateCollectorId]
      ,[UpdateDatetime]
      ,[Version]
      ,[Fileversion]
      ,[Vsname]
      ,[Checksum]
  FROM [Selecta Discovery].[SqlServer_Inventory].[Inventory]

