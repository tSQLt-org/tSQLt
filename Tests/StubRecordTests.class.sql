EXEC tSQLt.NewTestClass 'StubRecordTests';
GO
CREATE PROC StubRecordTests.[test StubRecord is deployed]
AS
BEGIN
    EXEC tSQLt.AssertObjectExists 'tSQLt.StubRecord';
END;
GO
