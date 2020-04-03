SELECT 
    '$(TestCaseFileName)' TestCaseSet,
    SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END) Success,
    SUM(CASE WHEN Result = 'Failure' THEN 1 ELSE 0 END) Failure,
    SUM(CASE WHEN Result = 'Error' THEN 1 ELSE 0 END) [Error]
  FROM tSQLt.TestResult;

:EXIT(SELECT COUNT(*) FROM tSQLt.TestResult WHERE Result != 'Success')

