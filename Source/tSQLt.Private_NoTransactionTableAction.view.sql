IF OBJECT_ID('tSQLt.Private_NoTransactionTableAction') IS NOT NULL DROP VIEW tSQLt.Private_NoTransactionTableAction;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_NoTransactionTableAction
AS
SELECT *
  FROM(
    VALUES('[tSQLt].[Private_NewTestClassList]','Restore'), -- perhaps Remove is more appropriate
          ('[tSQLt].[Run_LastExecution]','Restore'), -- perhaps Remove is more appropriate
          ('[tSQLt].[Private_Configurations]','Restore'),
          ('[tSQLt].[CaptureOutputLog]','Ignore'), -- technically this should be truncated, but it already is at the beginning of Run.
          ('[tSQLt].[Private_RenamedObjectLog]','Ignore'),
          ('[tSQLt].[TestResult]','Ignore')
  )X(Name, Action);
GO
