IF OBJECT_ID('tSQLt.Private_SetConfiguration') IS NOT NULL DROP PROCEDURE tSQLt.Private_SetConfiguration;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_SetConfiguration
  @Name NVARCHAR(100),
  @Value SQL_VARIANT
AS
BEGIN
  IF(EXISTS(SELECT 1 FROM tSQLt.Private_Configurations WITH(ROWLOCK,UPDLOCK) WHERE Name = @Name))
  BEGIN
    UPDATE tSQLt.Private_Configurations SET
           Value = @Value
     WHERE Name = @Name;
  END;
  ELSE
  BEGIN
     INSERT tSQLt.Private_Configurations(Name,Value)
     VALUES(@Name,@Value);
  END;
END;
GO
---Build-
GO
