IF OBJECT_ID('tSQLt.Private_NullCellTable') IS NOT NULL DROP TABLE tSQLt.Private_NullCellTable;
GO
CREATE TABLE tSQLt.Private_NullCellTable(
  I INT 
);
GO

INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (NULL);
GO

CREATE TRIGGER tSQLt.Private_NullCellTable_StopDeletes ON tSQLt.Private_NullCellTable INSTEAD OF DELETE, INSERT, UPDATE
AS
BEGIN
  RETURN;
END;
GO
