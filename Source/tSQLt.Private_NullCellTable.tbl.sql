IF OBJECT_ID('tSQLt.Private_NullCellTable_PreventTruncate') IS NOT NULL DROP TABLE tSQLt.Private_NullCellTable_PreventTruncate;
IF OBJECT_ID('tSQLt.Private_NullCellTable') IS NOT NULL DROP TABLE tSQLt.Private_NullCellTable;
GO
---Build+
GO
CREATE TABLE tSQLt.Private_NullCellTable(
  I INT CONSTRAINT[U:tSQLt.Private_NullCellTable] UNIQUE CLUSTERED
);
GO

CREATE TABLE tSQLt.Private_NullCellTable_PreventTruncate (
  I INT CONSTRAINT[FK:tSQLt.Private_NullCellTable(I)] FOREIGN KEY REFERENCES tSQLt.Private_NullCellTable(I)
);
GO

INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (NULL);
GO

CREATE TRIGGER tSQLt.Private_NullCellTable_StopModifications ON tSQLt.Private_NullCellTable INSTEAD OF DELETE, INSERT, UPDATE
AS
BEGIN
  IF EXISTS (SELECT 1 FROM tSQLt.Private_NullCellTable) RETURN;
  INSERT INTO tSQLt.Private_NullCellTable VALUES (NULL);
END;
GO

