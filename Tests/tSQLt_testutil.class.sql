/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
IF OBJECT_ID('tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects') IS NOT NULL EXEC('EXEC tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects');
GO
EXEC tSQLt.DropClass tSQLt_testutil;
GO

CREATE SCHEMA tSQLt_testutil;
GO
CREATE PROC tSQLt_testutil.ReThrow @msg NVARCHAR(MAX) = '' AS SET @msg = @msg + '[Msg '+LTRIM(STR(ERROR_NUMBER()))+', Level '+LTRIM(STR(ERROR_SEVERITY()))+', State '+LTRIM(STR(ERROR_STATE()))+ISNULL(', Procedure '+ERROR_PROCEDURE(),'')+', Line '+LTRIM(STR(ERROR_LINE()))+']'+ERROR_MESSAGE();RAISERROR(@msg,16,10);
GO
CREATE PROC tSQLt_testutil.assertFailCalled
    @Command NVARCHAR(MAX),
    @Message VARCHAR(MAX)
AS
BEGIN
    DECLARE @CallCount INT;
    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;
      EXEC tSQLt.SpyProcedure 'tSQLt.Fail','RAISERROR(''tSQLt_testutil.assertFailCalled.INTERNAL'',16,10);';
      BEGIN TRY
        EXEC (@Command);
      END TRY
      BEGIN CATCH
      END CATCH;
      SELECT @CallCount = COUNT(1) FROM tSQLt.Fail_SpyProcedureLog;
    ROLLBACK TRAN @TranName;
    COMMIT TRAN;

    IF (@CallCount = 0)
    BEGIN
      EXEC tSQLt.Fail @Message;
    END;
END;
GO

CREATE PROC tSQLt_testutil.AssertFailMessageEquals
    @Command NVARCHAR(MAX),
    @ExpectedMessage NVARCHAR(MAX),
    @Message0 VARCHAR(MAX) = NULL,
    @Message1 VARCHAR(MAX) = NULL,
    @Message2 VARCHAR(MAX) = NULL,
    @Message3 VARCHAR(MAX) = NULL,
    @Message4 VARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(MAX);
    SELECT  @Message = 
        COALESCE(@Message0, '')
      + COALESCE(@Message1, '')
      + COALESCE(@Message2, '')
      + COALESCE(@Message3, '')
      + COALESCE(@Message4, '');

    DECLARE @ActualMessage NVARCHAR(MAX);

    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;
      EXEC tSQLt.SpyProcedure 'tSQLt.Fail','RAISERROR(''tSQLt_testutil.assertFailCalled.INTERNAL'',16,10);';
      BEGIN TRY
        EXEC (@Command);
      END TRY
      BEGIN CATCH
        IF(ISNULL(ERROR_PROCEDURE(),'')<>'Fail')
        BEGIN
          ROLLBACK TRAN @TranName;
          COMMIT;
          EXEC tSQLt_testutil.ReThrow;
        END
      END CATCH;
      SELECT @ActualMessage = 
          COALESCE(Message0, '')--should be '!NULL!' but default parameters are not currently supported by SpyProcedure
        + COALESCE(Message1, '')
        + COALESCE(Message2, '')
        + COALESCE(Message3, '')
        + COALESCE(Message4, '')
        + COALESCE(Message5, '')
        + COALESCE(Message6, '')
        + COALESCE(Message7, '')
        + COALESCE(Message8, '')
        + COALESCE(Message9, '') FROM tSQLt.Fail_SpyProcedureLog;
    ROLLBACK TRAN @TranName;
    COMMIT TRAN;

    EXEC tSQLt.AssertEqualsString @ExpectedMessage, @ActualMessage, @Message;
END;
GO

CREATE PROC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses
AS
BEGIN
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  DECLARE tests CURSOR LOCAL FAST_FORWARD FOR
   SELECT DISTINCT s.name AS testClassName
     FROM sys.extended_properties ep
     JOIN sys.schemas s
       ON ep.major_id = s.schema_id
    WHERE ep.name = N'tSQLt.TestClass';

  OPEN tests;
  
  FETCH NEXT FROM tests INTO @TestClassName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC sp_dropextendedproperty @name = 'tSQLt.TestClass',
                                 @level0type = 'SCHEMA',
                                 @level0name = @TestClassName;
    
    FETCH NEXT FROM tests INTO @TestClassName;
  END;
  
  CLOSE tests;
  DEALLOCATE tests;
END;
GO

CREATE PROCEDURE tSQLt_testutil.AssertLike 
  @ExpectedPattern NVARCHAR(MAX),
  @Actual NVARCHAR(MAX),
  @Message NVARCHAR(MAX) = ''
AS
BEGIN
    IF ((@Actual LIKE @ExpectedPattern) OR (@Actual IS NULL AND @ExpectedPattern IS NULL))
      RETURN 0;

    DECLARE @Msg NVARCHAR(MAX);
    SELECT @Msg = CHAR(13)+CHAR(10)+'Expected: <' + ISNULL(@ExpectedPattern, 'NULL') + 
                  '>'+CHAR(13)+CHAR(10)+' but was: <' + ISNULL(@Actual, 'NULL') + '>';
    EXEC tSQLt.Fail @Message, @Msg;
END

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
