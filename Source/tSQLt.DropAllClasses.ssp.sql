IF OBJECT_ID('tSQLt.DropAllClasses') IS NOT NULL DROP PROCEDURE tSQLt.DropAllClasses;
GO
---Build+
CREATE PROCEDURE tSQLt.DropAllClasses
AS
BEGIN
  DECLARE TestClass CURSOR LOCAL FAST_FORWARD
  FOR
  SELECT s.name
    FROM sys.schemas s
      JOIN sys.extended_properties b
        ON s.schema_id = b.major_id
          AND b.class = 3
          AND b.name = 'tSQLt.TestClass';

  DECLARE @schema sysname;
  OPEN TestClass;

  WHILE 1 = 1
  BEGIN
    FETCH NEXT FROM TestClass INTO @schema;
    IF @@FETCH_STATUS <> 0
      BREAK;
    EXEC tSQLt.DropClass @ClassName = @schema;
  END;

  CLOSE TestClass;
  DEALLOCATE TestClass;
END;
---Build-
GO
