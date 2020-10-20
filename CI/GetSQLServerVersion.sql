 SELECT 
   SUSER_NAME() LoginName,
   SYSDATETIME() [TimeStamp],
   @@VERSION [VersionDetail], 
   SERVERPROPERTY('ProductVersion') AS ProductVersion,
   SERVERPROPERTY('ProductLevel') AS ProductLevel,
   CASE (SELECT PARSENAME(XX,4)+'.'+PARSENAME(XX,3) FROM (SELECT (CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX)))XX)X)
     WHEN '9.0' THEN '2005'
     WHEN '10.0' THEN '2008'
     WHEN '10.50' THEN '2008R2'
     WHEN '11.0' THEN '2012'
     WHEN '12.0' THEN '2014'
     WHEN '13.0' THEN '2016'
     WHEN '14.0' THEN '2017'
     WHEN '15.0' THEN '2019'
     ELSE 'Unknown'
    END SQLVersion
