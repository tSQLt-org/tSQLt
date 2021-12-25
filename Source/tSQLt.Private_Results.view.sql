IF OBJECT_ID('tSQLt.Private_Results') IS NOT NULL DROP VIEW tSQLt.Private_Results;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_Results
AS
SELECT CAST(Severity AS INT) Severity,CAST(Result AS NVARCHAR(MAX)) Result
  FROM(
    VALUES(1, 'Success')
    ,
          (2, 'Skipped'),
          (3, 'Failure'),
          (4, 'Error'),
          (5, 'Abort'),
          (6, 'FATAL')
  )X(Severity, Result);
GO

