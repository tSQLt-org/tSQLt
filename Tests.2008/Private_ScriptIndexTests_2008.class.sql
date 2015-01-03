EXEC tSQLt.NewTestClass 'Private_ScriptIndexTests_2008';
GO
CREATE PROCEDURE Private_ScriptIndexTests_2008.[test handles filter]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C3]DESC)INCLUDE([C4],[C2])WHERE([C1]=(3));';
END;
GO
