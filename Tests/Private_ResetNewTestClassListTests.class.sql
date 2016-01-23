EXEC tSQLt.NewTestClass 'Private_ResetNewTestClassListTests';
GO
CREATE PROCEDURE Private_ResetNewTestClassListTests.[test does not fail if Private_NewTestClassList is empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';

  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.Private_ResetNewTestClassList;
END;
GO
CREATE PROCEDURE Private_ResetNewTestClassListTests.[test empties Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc1');
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc2');
  INSERT INTO tSQLt.Private_NewTestClassList VALUES('tc3');

  EXEC tSQLt.Private_ResetNewTestClassList;

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NewTestClassList';
END;
GO
