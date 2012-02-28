IF OBJECT_ID('tSQLt.Private_RenamedObjectLog') IS NOT NULL DROP TABLE tSQLt.Private_RenamedObjectLog;
GO
---Build+
CREATE TABLE tSQLt.Private_RenamedObjectLog (
  Id INT IDENTITY(1,1) CONSTRAINT PK__Private_RenamedObjectLog__Id PRIMARY KEY CLUSTERED,
  ObjectId INT NOT NULL,
  OriginalName NVARCHAR(MAX) NOT NULL
);
---Build-
GO