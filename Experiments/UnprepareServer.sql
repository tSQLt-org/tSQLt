GO
EXEC tSQLt.RemoveAssemblyKey;
GO
EXEC sp_configure @configname='clr enabled', @configvalue=0;
GO
RECONFIGURE
GO
EXEC sp_configure @configname='show adv', @configvalue=1;
GO
RECONFIGURE
GO
EXEC sp_configure @configname='clr stri', @configvalue=1;
GO
RECONFIGURE
GO
EXEC sp_configure @configname='show adv', @configvalue=0;
GO
RECONFIGURE
GO
SELECT * FROM master.sys.configurations AS C WHERE name LIKE '%clr%'
SELECT * FROM master.sys.server_principals AS SP WHERE SP.name LIKE '%tSQLt%';
SELECT * FROM master.sys.asymmetric_keys AS AK WHERE AK.name LIKE '%tSQLt%';
SELECT * FROM master.sys.trusted_assemblies AS TA --WHERE SP.name LIKE '%tSQLt%';
SELECT * FROM master.sys.assemblies AS AK WHERE AK.name LIKE '%tSQLt%';
SELECT name,AK.is_trustworthy_on FROM master.sys.databases AS AK WHERE AK.name LIKE '%tSQLt%';
SELECT * FROM sys.server_permissions AS SP WHERE SP.grantee_principal_id = (SELECT SP2.principal_id FROM sys.server_principals AS SP2 WHERE SP2.name = 'tSQLtAssemblyKey');
--||--
--^^--Needs manual review for now
--||--
