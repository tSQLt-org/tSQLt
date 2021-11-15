IF OBJECT_ID('tSQLt.Private_ResettSQLtTableAction') IS NOT NULL DROP VIEW tSQLt.Private_ResettSQLtTableAction;
GO
---Build+
GO
CREATE VIEW tSQLt.Private_ResettSQLtTableAction
AS
SELECT *
  FROM(
    VALUES('[tSQLt].[Private_NewTestClassList]','Restore'),
          ('[tSQLt].[Run_LastExecution]','Restore'),
          ('[tSQLt].[Private_Configurations]','Restore'),
          ('[tSQLt].[CaptureOutputLog]','Ignore'),
          ('[tSQLt].[Private_RenamedObjectLog]','Ignore'),
          ('[tSQLt].[TestResult]','Ignore')
  )X(Name, Action);
GO
