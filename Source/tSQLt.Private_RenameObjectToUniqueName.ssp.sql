IF OBJECT_ID('tSQLt.Private_RenameObjectToUniqueName') IS NOT NULL DROP PROCEDURE tSQLt.Private_RenameObjectToUniqueName;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueName
    @SchemaName NVARCHAR(MAX),
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   SET @NewName=tSQLt.Private::CreateUniqueObjectName();

   DECLARE @RenameCmd NVARCHAR(MAX);
   SET @RenameCmd = 'EXEC sp_rename ''' + 
                          @SchemaName + '.' + @ObjectName + ''', ''' + 
                          @NewName + ''';';
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName, @ObjectName;


   EXEC tSQLt.SuppressOutput @RenameCmd;

END;
---Build-
GO
