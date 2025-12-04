IF OBJECT_ID('tSQLt.AssertObjectExists') IS NOT NULL DROP PROCEDURE tSQLt.AssertObjectExists;
GO
---Build+
CREATE PROCEDURE tSQLt.AssertObjectExists
    @ObjectName NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = '',
    @TypeName NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX);
    DECLARE @ObjectId INT;
    DECLARE @ActualType NVARCHAR(128);

    IF(@ObjectName LIKE '#%')
    BEGIN
     SET @ObjectId = OBJECT_ID('tempdb..'+@ObjectName);
     IF @ObjectId IS NULL
     BEGIN
         SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @Msg;
         RETURN 1;
     END;

     IF @TypeName IS NOT NULL
     BEGIN
         SELECT @ActualType = type_desc FROM tempdb.sys.objects WHERE object_id = @ObjectId;
         IF @ActualType IS NULL OR @ActualType <> UPPER(@TypeName)
         BEGIN
             SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' exists but is not of type ''' + @TypeName + '''' +
                           CASE WHEN @ActualType IS NOT NULL THEN ' (found type: ''' + @ActualType + ''')' ELSE '' END;
             EXEC tSQLt.Fail @Message, @Msg;
             RETURN 1;
         END;
     END;
    END
    ELSE
    BEGIN
     SET @ObjectId = OBJECT_ID(@ObjectName);
     IF @ObjectId IS NULL
     BEGIN
         SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @Msg;
         RETURN 1;
     END;

     IF @TypeName IS NOT NULL
     BEGIN
         SELECT @ActualType = type_desc FROM sys.objects WHERE object_id = @ObjectId;
         IF @ActualType IS NULL OR @ActualType <> UPPER(@TypeName)
         BEGIN
             SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' exists but is not of type ''' + @TypeName + '''' +
                           CASE WHEN @ActualType IS NOT NULL THEN ' (found type: ''' + @ActualType + ''')' ELSE '' END;
             EXEC tSQLt.Fail @Message, @Msg;
             RETURN 1;
         END;
     END;
    END;
    RETURN 0;
END;
---Build-
GO

