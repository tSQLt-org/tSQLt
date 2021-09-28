  EXEC tSQLt.NewTestClass 'Private_NullCellTableTests';
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test table contains a single null cell]
  AS
  BEGIN
     CREATE TABLE Private_NullCellTableTests.Expected (I INT);
     INSERT INTO Private_NullCellTableTests.Expected(I) VALUES (NULL);
     
     EXEC tSQLt.AssertEqualsTable 'Private_NullCellTableTests.Expected', 'tSQLt.Private_NullCellTable';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable]
    @Statement NVARCHAR(MAX)
  AS
  BEGIN
    CREATE TABLE Private_NullCellTableTests.Expected (I INT);
    INSERT INTO Private_NullCellTableTests.Expected(I) VALUES (NULL);

    BEGIN TRY  
      EXEC @Statement;
    END TRY
    BEGIN CATCH
      -- Left intentionally empty
    END CATCH;
  
    EXEC tSQLt.AssertEqualsTable 'Private_NullCellTableTests.Expected', 'tSQLt.Private_NullCellTable';
  
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot insert second NULL row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (NULL);';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot insert a non-NULL row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (5);';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot delete row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'DELETE FROM tSQLt.Private_NullCellTable;';
  END;
  GO
  
  CREATE PROCEDURE Private_NullCellTableTests.[test cannot update row]
  AS
  BEGIN
    EXEC Private_NullCellTableTests.[AssertStatementPerformsNoDataChangeToTable] 'UPDATE tSQLt.Private_NullCellTable SET I = 13;';
  END;
  GO

  CREATE PROCEDURE Private_NullCellTableTests.[test can insert a row if the table is empty]
  AS
  BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NullCellTable';
    EXEC tSQLt.ApplyTrigger @TableName = 'tSQLt.Private_NullCellTable', @TriggerName= 'tSQLt.Private_NullCellTable_StopModifications';

    INSERT INTO tSQLt.Private_NullCellTable VALUES (NULL);

    SELECT * INTO #Actual FROM tSQLt.Private_NullCellTable;

    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

    INSERT INTO #Expected VALUES (NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
  END;
  GO

  CREATE PROCEDURE Private_NullCellTableTests.[test any insert will insert NULL row if table is empty]
  AS
  BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NullCellTable';
    EXEC tSQLt.ApplyTrigger @TableName = 'tSQLt.Private_NullCellTable', @TriggerName= 'tSQLt.Private_NullCellTable_StopModifications';

    INSERT INTO tSQLt.Private_NullCellTable VALUES (10),(11),(12);

    SELECT * INTO #Actual FROM tSQLt.Private_NullCellTable;

    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

    INSERT INTO #Expected VALUES (NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
  END;
  GO

  CREATE PROCEDURE Private_NullCellTableTests.[test any update will insert NULL row if table is empty]
  AS
  BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NullCellTable';
    EXEC tSQLt.ApplyTrigger @TableName = 'tSQLt.Private_NullCellTable', @TriggerName= 'tSQLt.Private_NullCellTable_StopModifications';

    UPDATE tSQLt.Private_NullCellTable SET I = I WHERE 1=0;

    SELECT * INTO #Actual FROM tSQLt.Private_NullCellTable;

    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

    INSERT INTO #Expected VALUES (NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
  END;
  GO

  CREATE PROCEDURE Private_NullCellTableTests.[test any delete will insert NULL row if table is empty]
  AS
  BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NullCellTable';
    EXEC tSQLt.ApplyTrigger @TableName = 'tSQLt.Private_NullCellTable', @TriggerName= 'tSQLt.Private_NullCellTable_StopModifications';

    DELETE tSQLt.Private_NullCellTable WHERE 1=0;

    SELECT * INTO #Actual FROM tSQLt.Private_NullCellTable;

    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

    INSERT INTO #Expected VALUES (NULL);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
  END;
  GO
