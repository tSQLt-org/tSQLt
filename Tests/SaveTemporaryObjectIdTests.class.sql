EXEC tSQLt.NewTestClass 'SaveTemporaryObjectIdTests';
GO
CREATE PROC SaveTemporaryObjectIdTests.[test row is inserted if it does not exist]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'tSQLt.TemporaryObject';

    CREATE TABLE #Expected (TempObjectId INT, OrgObjectId INT);
    CREATE TABLE #Actual (TempObjectId INT, OrgObjectId INT);

    INSERT INTO #Expected ( TempObjectId ,OrgObjectId )
    VALUES ( 1, 1);

    EXEC tSQLt.SaveTemporaryObjectId @TempObjectId = 1, @OrgObjectId = 1;

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';

END;
GO