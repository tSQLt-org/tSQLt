EXEC tSQLt.NewTestClass 'Private_ScriptIndexTests_2012';
GO
CREATE PROCEDURE Private_ScriptIndexTests_2012.[test handles nonclustered columnstore index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE NONCLUSTERED COLUMNSTORE INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1],[C3]);';
END;
GO



GO

