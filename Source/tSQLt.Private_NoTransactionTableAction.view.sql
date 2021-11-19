IF OBJECT_ID('tSQLt.Private_NoTransactionTableAction') IS NOT NULL DROP VIEW tSQLt.Private_NoTransactionTableAction;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_NoTransactionTableAction
AS
SELECT *
  FROM(
    VALUES('[tSQLt].[Private_NewTestClassList]','Ignore'),
          ('[tSQLt].[Run_LastExecution]','Ignore'),
          ('[tSQLt].[Private_Configurations]','Restore'),
          ('[tSQLt].[CaptureOutputLog]','Truncate'),
          ('[tSQLt].[Private_RenamedObjectLog]','Ignore'),
          ('[tSQLt].[TestResult]','Ignore')
  )X(Name, Action);
GO
