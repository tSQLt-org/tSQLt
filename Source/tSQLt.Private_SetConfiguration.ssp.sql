IF OBJECT_ID('tSQLt.Private_SetConfiguration') IS NOT NULL DROP PROCEDURE tSQLt.Private_SetConfiguration;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_SetConfiguration
  @Name NVARCHAR(100),
  @Value SQL_VARIANT
AS
BEGIN
  MERGE tSQLt.Private_Configurations WITH(ROWLOCK,UPDLOCK) AS T
  USING (VALUES(@Name,@Value))AS V(Name,Value)
     ON T.Name = V.Name
   WHEN MATCHED THEN UPDATE SET
     Value = V.Value
   WHEN NOT MATCHED BY TARGET THEN 
     INSERT(Name,Value)
     VALUES(V.Name,V.Value);
END;
GO
---Build-
GO
