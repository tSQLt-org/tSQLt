IF OBJECT_ID('tSQLt.Private_Seize_NoTruncate') IS NOT NULL DROP TABLE tSQLt.Private_Seize_NoTruncate;
IF OBJECT_ID('tSQLt.Private_Seize') IS NOT NULL DROP TABLE tSQLt.Private_Seize;
GO
---Build+
GO
CREATE TABLE tSQLt.Private_Seize(
  Kaput BIT CONSTRAINT [Private_Seize:PK] PRIMARY KEY CONSTRAINT [Private_Seize:CHK] CHECK(Kaput=1)
);
GO
CREATE TABLE tSQLt.Private_Seize_NoTruncate(
  NoTruncate BIT CONSTRAINT [Private_Seize_NoTruncate(NoTruncate):FK] FOREIGN KEY REFERENCES tSQLt.Private_Seize(Kaput)
);
GO
CREATE TRIGGER tSQLt.Private_Seize_Stop ON tSQLt.Private_Seize INSTEAD OF DELETE,UPDATE
AS
BEGIN 
  RAISERROR('This is a private table that you should not mess with!',16,10);
END;
GO

  