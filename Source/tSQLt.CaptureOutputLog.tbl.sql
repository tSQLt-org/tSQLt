IF OBJECT_ID('tSQLt.CaptureOutputLog') IS NOT NULL DROP TABLE tSQLt.CaptureOutputLog;
---Build+
CREATE TABLE tSQLt.CaptureOutputLog (
  Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
  OutputText NVARCHAR(MAX)
);
---Build-
