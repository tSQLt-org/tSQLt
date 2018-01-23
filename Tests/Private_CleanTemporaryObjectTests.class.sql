EXEC tSQLt.NewTestClass 'Private_CleanTemporaryObjectTests';
GO
CREATE PROC Private_CleanTemporaryObjectTests.[test all TemporaryObject data is removed]
AS
BEGIN
    EXEC tSQLt.FakeTable @Tablename = N'tSQLt.Private_CleanTemporaryObject';

    INSERT INTO tSQLt.Private_CleanTemporaryObject (TempObjectId, OrgObjectId)
    VALUES (1,1),(2,2);

    EXEC tSQLt.Private_CleanTemporaryObject;

    EXEC tSQLt.AssertEmptyTable @TableName = N'tSQLt.Private_CleanTemporaryObject';
END;
GO