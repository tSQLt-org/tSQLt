IF OBJECT_ID('tSQLt.InstallExternalAccessKey') IS NOT NULL DROP PROCEDURE tSQLt.InstallExternalAccessKey;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.InstallExternalAccessKey
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 'CREATE ASSEMBLY tSQLtExternalAccessKey FROM '+CONVERT(NVARCHAR(MAX),AF.content,1)+';'
    FROM sys.assembly_files AS AF
    JOIN sys.assemblies AS A
      ON AF.assembly_id = A.assembly_id
   WHERE A.name = 'tSQLtCLR';

  EXEC master.sys.sp_executesql @cmd;
  CREATE ASYMMETRIC KEY tSQLtExternalAccessKey FROM ASSEMBLY tSQLtExternalAccessKey  
  
END;
GO
---Build-
GO
