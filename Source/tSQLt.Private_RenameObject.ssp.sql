IF OBJECT_ID('tSQLt.Private_RenameObject') IS NOT NULL DROP PROCEDURE tSQLt.Private_RenameObject;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_RenameObject
    @SchemaName NVARCHAR(MAX),
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX)
AS
BEGIN
   DECLARE @RenameCmd NVARCHAR(MAX);
   SET @RenameCmd = 'EXEC sp_rename ''' + 
                    @SchemaName + '.' + @ObjectName + ''', ''' + 
                    @NewName + ''',''OBJECT'';';
   
   EXEC tSQLt.SuppressOutput @RenameCmd;
END;
---Build-
GO
