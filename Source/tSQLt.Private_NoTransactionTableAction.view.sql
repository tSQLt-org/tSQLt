IF OBJECT_ID('tSQLt.Private_NoTransactionTableAction') IS NOT NULL DROP VIEW tSQLt.Private_NoTransactionTableAction;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_NoTransactionTableAction
AS
SELECT CAST(Name AS NVARCHAR(MAX)) Name, CAST(Action AS NVARCHAR(MAX)) Action
  FROM(
    VALUES('[tSQLt].[Private_NewTestClassList]','Hide'),
          ('[tSQLt].[Run_LastExecution]','Hide'),
          ('[tSQLt].[Private_Configurations]','Restore'),
          ('[tSQLt].[CaptureOutputLog]','Truncate'),
          ('[tSQLt].[Private_RenamedObjectLog]','Ignore'),
          ('[tSQLt].[Private_Seize]','Ignore'),
          ('[tSQLt].[Private_Seize_NoTruncate]','Ignore'),
          ('[tSQLt].[TestResult]','Restore')
  )X(Name, Action);
GO
