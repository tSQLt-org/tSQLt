EXEC tSQLt.NewTestClass 'Private_ScriptIndexTests_2014';
GO
CREATE PROCEDURE Private_ScriptIndexTests_2014.[test handles clustered columnstore index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE CLUSTERED COLUMNSTORE INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1];';
END;
GO
