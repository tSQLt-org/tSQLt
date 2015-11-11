EXEC tSQLt.NewTestClass 'AssertStringInTests_2008';
GO
CREATE PROCEDURE AssertStringInTests_2008.[test fails if set is empty]
AS
BEGIN
  
  EXEC tSQLt_testutil.assertFailCalled @Command = 
    'DECLARE @ExpectedSet tSQLt.AssertStringTable;
     EXEC tSQLt.AssertStringIn 
             @Expected = @ExpectedSet, 
             @Actual = ''Some String'';';
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test succeeds if value is the only element]
AS
BEGIN
  
  DECLARE @ExpectedSet tSQLt.AssertStringTable;
  INSERT INTO @ExpectedSet(value)VALUES('Some String');

  EXEC tSQLt.AssertStringIn 
          @Expected = @ExpectedSet, 
          @Actual = 'Some String';

END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test succeeds if value is one of many elements]
AS
BEGIN
  
  DECLARE @ExpectedSet tSQLt.AssertStringTable;
  INSERT INTO @ExpectedSet(value)VALUES('String 1'),('String 2'),('Some String'),('String 4'),('String 5');

  EXEC tSQLt.AssertStringIn 
          @Expected = @ExpectedSet, 
          @Actual = 'Some String';

END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test includes string and ordered table in fail message]
AS
BEGIN
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  INSERT INTO #ExpectedSet(value)VALUES('String 3'),('String 5'),('String 4'),('String 1'),('String 2');
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    INSERT INTO @ExpectedSet(value)SELECT value FROM #ExpectedSet;

    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = ''Missing String'';
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  '<Missing String>' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Actual = 'NULL']
AS
BEGIN
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  INSERT INTO #ExpectedSet(value)VALUES('String 3'),('String 5'),('String 4'),('String 1'),('String 2');
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    INSERT INTO @ExpectedSet(value)SELECT value FROM #ExpectedSet;

    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL;
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  'NULL' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Expected is empty]
AS
BEGIN
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = ''Missing String'';
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  '<Missing String>' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Expected is empty and @Actual is NULL]
AS
BEGIN
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL;
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  'NULL' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROC AssertStringInTests_2008.[test AssertStringIn passes supplied message before original failure message when calling fail]
AS
BEGIN
  EXEC tSQLt_testutil.AssertFailMessageLike 
    '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL,
            @Message = ''{MyMessage}'';
  ',
  '{MyMessage}%NULL%value%';
END;
GO


--message