IF OBJECT_ID('tSQLt.DropAllClasses') IS NOT NULL DROP PROCEDURE tSQLt.DropAllClasses;
GO
---Build+
CREATE PROCEDURE tSQLt.DropAllClasses
AS
BEGIN
  DECLARE TestClass CURSOR LOCAL FAST_FORWARD
  FOR
  SELECT Name FROM tSQLt.TestClasses;

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
