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
  