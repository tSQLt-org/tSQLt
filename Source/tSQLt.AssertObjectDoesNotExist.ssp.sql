IF OBJECT_ID('tSQLt.AssertObjectDoesNotExist') IS NOT NULL DROP PROCEDURE tSQLt.AssertObjectDoesNotExist;
GO
---Build+
CREATE PROCEDURE tSQLt.AssertObjectDoesNotExist
    @ObjectName NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
     DECLARE @Msg NVARCHAR(MAX);
     IF OBJECT_ID(@ObjectName) IS NOT NULL
     OR(@ObjectName LIKE '#%' AND OBJECT_ID('tempdb..'+@ObjectName) IS NOT NULL)
     BEGIN
         SELECT @Msg = '''' + @ObjectName + ''' does exist!';
         EXEC tSQLt.Fail @Message,@Msg;
     END;
END;
---Build-
GO

