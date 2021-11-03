EXEC tSQLt.NewTestClass 'SpyProcedureTests';
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''Original InnerProcedure was executed'';');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure with a parameter]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX) AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with a parameter';

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow tester to not execute behavior of procedure with multiple parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log calls]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';

    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log calls with varchar parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(10), @P3 VARCHAR(8000) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure 'with', 'multiple', 'parameters';


    IF NOT EXISTS(SELECT 1
                   FROM dbo.InnerProcedure_SpyProcedureLog
                  WHERE P1 = 'with'
                    AND P2 = 'multiple'
                    AND P3 = 'parameters')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END;

END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow NULL values for sysname parms]
AS
BEGIN
  EXEC('CREATE PROC dbo.InnerProcedure @P1 sysname ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyProcedureLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should allow NULL values for user defined types created as not nullable]
AS
BEGIN
  EXEC ('CREATE TYPE SpyProcedureTests.MyType FROM INT NOT NULL;');
  
  EXEC('CREATE PROC dbo.InnerProcedure @P1 SpyProcedureTests.MyType ' +
       'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
  EXEC @InnerProcedure NULL;

  SELECT P1
    INTO #Actual
    FROM dbo.InnerProcedure_SpyProcedureLog;

  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected(P1) VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log call when output parameters are present]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log values of output parameters if input was provided for them]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    SET @ActualOutputValue = 'HELLO';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'HELLO')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should log values if a mix of input an output parameters are provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT, @P2 INT, @P3 BIT OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = 'PARAM1', @P2 = 2, @P3 = 0;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'PARAM1'
                     AND P2 = 2
                     AND P3 = 0)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure should not log the default values of parameters if no value is provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) = ''MY DEFAULT'' AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure can be given a command to execute]
AS
BEGIN
    EXEC ('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''InnerProcedure was executed'';');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'RETURN 1';
    
    DECLARE @ReturnVal INT;
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @ReturnVal = @InnerProcedure;
    
    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;
    
    EXEC tSQLt.AssertEquals 1, @ReturnVal;
END;
GO

CREATE PROC SpyProcedureTests.[test command given to SpyProcedure can be used to set output parameters]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'SET @P1 = ''HELLO'';';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @ActualOutputValue OUT;
    
    EXEC tSQLt.AssertEqualsString 'HELLO', @ActualOutputValue;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure can have a cursor output parameter]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 CURSOR VARYING OUTPUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @OutputCursor CURSOR;
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'dbo.InnerProcedure'
    EXEC @InnerProcedure @P1 = @OutputCursor OUTPUT; 
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure raises appropriate error if the procedure does not exist]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      EXEC tSQLt.SpyProcedure 'SpyProcedureTests.DoesNotExist';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %DoesNotExist% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure raises appropriate error if the procedure name given references another type of object]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      CREATE TABLE SpyProcedureTests.dummy (i int);
      EXEC tSQLt.SpyProcedure 'SpyProcedureTests.dummy';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %dummy% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure handles procedure names with spaces]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE PROC SpyProcedureTests.[Spyee Proc] AS RETURN 0;');

    EXEC tSQLt.SpyProcedure 'SpyProcedureTests.[Spyee Proc]';
    
    DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'SpyProcedureTests.[Spyee Proc]'
    EXEC @InnerProcedure;
    
    SELECT *
      INTO #Actual
      FROM SpyProcedureTests.[Spyee Proc_SpyProcedureLog];
    
    SELECT 1 _id_
      INTO #Expected
     WHERE 0=1;

    INSERT #Expected
    SELECT 1;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure calls tSQLt.Private_RenameObjectToUniqueName on original proc]
AS
BEGIN
    DECLARE @ErrorRaised NVARCHAR(MAX); SET @ErrorRaised = 'No Error Raised';
    
    EXEC('CREATE PROC SpyProcedureTests.SpyeeProc AS RETURN 0;');

    EXEC tSQLt.SpyProcedure 'tSQLt.Private_RenameObjectToUniqueName','RAISERROR(''Intentional Error'', 16, 10)';
    
    BEGIN TRY
        EXEC tSQLt.SpyProcedure  'SpyProcedureTests.SpyeeProc';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = ERROR_MESSAGE();
    END CATCH
    
    EXEC tSQLt.AssertEqualsString 'Intentional Error', @ErrorRaised;
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure works if spyee has 100 parameters with 8000 bytes each]
AS
BEGIN
  IF OBJECT_ID('dbo.InnerProcedure') IS NOT NULL DROP PROCEDURE dbo.InnerProcedure;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.InnerProcedure('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' CHAR(8000)' [text()]
                   FROM tSQLt.F_Num(100)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ExpectedM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ActualM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  SELECT * 
    INTO #Actual1
    FROM #ActualM
   WHERE parameter_id<511;
  SELECT * 
    INTO #Expected1
    FROM #ExpectedM
   WHERE parameter_id<511;
   
  EXEC tSQLt.AssertEqualsTable '#Expected1','#Actual1';

  SELECT * 
    INTO #Actual2
    FROM #ActualM
   WHERE parameter_id>510;
  SELECT * 
    INTO #Expected2
    FROM #ExpectedM
   WHERE parameter_id>510;
   
  EXEC tSQLt.AssertEqualsTable '#Expected2','#Actual2';
END
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates char parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @CHAR1 CHAR(1),
             @CHAR8000 CHAR(8000),
             @VARCHAR1 VARCHAR(1),
             @VARCHAR8000 VARCHAR(8000),
             @VARCHARMAX VARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates binary parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @BINARY1 BINARY(1) =NULL,
             @BINARY4000 BINARY(3000) =NULL,
             @VARBINARY1 VARBINARY(1) =NULL,
             @VARBINARY4000 VARBINARY(3000) =NULL,
             @VARBINARYMAX VARBINARY(MAX) =NULL
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

     EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC SpyProcedureTests.[test SpyProcedure creates log which handles binary columns]
AS
BEGIN
    DECLARE @proc NVARCHAR(100); SET @proc = 'dbo.InnerProcedure';
    EXEC('CREATE PROC dbo.InnerProcedure(
             @VARBINARY8000 VARBINARY(8000) =NULL
          )
          AS BEGIN RETURN 0; END');


    EXEC tSQLt.SpyProcedure @proc;
     
    EXEC @proc @VARBINARY8000=0x111122223333444455556666777788889999;

    DECLARE @Actual VARBINARY(8000);
    SELECT @Actual = VARBINARY8000 FROM dbo.InnerProcedure_SpyProcedureLog;
    
    EXEC tSQLt.AssertEquals 0x111122223333444455556666777788889999, @Actual;
END;
GO


CREATE PROC SpyProcedureTests.[test SpyProcedure creates nchar parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @NCHAR1 NCHAR(1),
             @NCHAR4000 NCHAR(4000),
             @NVARCHAR1 NVARCHAR(1),
             @NVARCHAR4000 NVARCHAR(4000),
             @NVARCHARMAX NVARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure creates other parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @TINYINT TINYINT,
             @SMALLINT SMALLINT,
             @INT INT,
             @BIGINT BIGINT
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure handles length, precision, and scale correctly]
  AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @LENGTH1 VARCHAR(42) ,
             @LENGTH2 VARCHAR(MAX) ,
             @PRECISION_SCALE NUMERIC(21, 13) 
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure fails with error if spyee has more than 1020 parameters]
AS
BEGIN
  IF OBJECT_ID('dbo.Spyee') IS NOT NULL DROP PROCEDURE dbo.Spyee;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.Spyee('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' INT' [text()]
                   FROM tSQLt.F_Num(1021)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);
  DECLARE @Err VARCHAR(MAX);SET @Err = 'NO ERROR';
  BEGIN TRY
    EXEC tSQLt.SpyProcedure 'dbo.Spyee';
  END TRY
  BEGIN CATCH
    SET @Err = ERROR_MESSAGE();
  END CATCH
  
  IF @Err NOT LIKE '%dbo.Spyee%' AND @Err NOT LIKE '%1020 parameters%'
  BEGIN
      EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
  END;
  
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure works on procedure if type with same name exists]
AS
BEGIN
   CREATE TYPE SpyProcedureTests.ProcedureAndType FROM BIGINT;
   EXEC('CREATE PROC SpyProcedureTests.ProcedureAndType AS RETURN;');

   EXEC tSQLt.SpyProcedure @ProcedureName = 'SpyProcedureTests.ProcedureAndType';

   EXEC ('EXEC SpyProcedureTests.ProcedureAndType');

   SELECT _id_
     INTO #Actual
     FROM SpyProcedureTests.ProcedureAndType_SpyProcedureLog;

   SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
   
   INSERT INTO #Expected
   VALUES(1);

   EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure works on procedure if table type with same name exists]
AS
BEGIN
   CREATE TYPE SpyProcedureTests.ProcedureAndType AS TABLE(id INT);
   EXEC('CREATE PROC SpyProcedureTests.ProcedureAndType AS RETURN;');
--SELECT OBJECT_ID('SpyProcedureTests.ProcedureAndType'),TYPE_ID('SpyProcedureTests.ProcedureAndType');
   EXEC tSQLt.SpyProcedure @ProcedureName = 'SpyProcedureTests.ProcedureAndType';

   EXEC ('EXEC SpyProcedureTests.ProcedureAndType');

   SELECT _id_
     INTO #Actual
     FROM SpyProcedureTests.ProcedureAndType_SpyProcedureLog;

   SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
   
   INSERT INTO #Expected
   VALUES(1);

   EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE TYPE SpyProcedureTests.TableType1001 AS TABLE(SomeInt INT, SomeVarChar VARCHAR(10));
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure can have a table type parameter]
AS
BEGIN
  EXEC('CREATE PROC SpyProcedureTests.InnerProcedure @P1 SpyProcedureTests.TableType1001 READONLY AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

  EXEC tSQLt.SpyProcedure 'SpyProcedureTests.InnerProcedure';

  DECLARE @TableParameter SpyProcedureTests.TableType1001;
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(10,'S1');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(202,'V2');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(3303,'C3');

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'SpyProcedureTests.InnerProcedure'
  EXEC @InnerProcedure @P1 = @TableParameter; 

  SELECT RowNode.value('SomeInt[1]','INT') SomeInt,RowNode.value('SomeVarChar[1]','VARCHAR(10)') SomeVarChar
    INTO #Actual
    FROM SpyProcedureTests.InnerProcedure_SpyProcedureLog
   CROSS APPLY P1.nodes('P1/row') AS N(RowNode);  
  
  SELECT *
  INTO #Expected
  FROM @TableParameter AS TP;
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO
CREATE PROC SpyProcedureTests.[test Private_GenerateCreateProcedureSpyStatement does not create log table when @LogTableName is NULL]
AS
BEGIN
    EXEC('CREATE PROC dbo.OriginalInnerProcedure AS RETURN;');

    DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.OriginalInnerProcedure');

    DECLARE @CreateProcedureStatement NVARCHAR(MAX);
    DECLARE @CreateLogTableStatement NVARCHAR(MAX);

    EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement
           @ProcedureObjectId = @ProcedureObjectId,
           @OriginalProcedureName = 'dbo.SpiedInnerProcedure',  /*using different name to simulate renaming*/
           @LogTableName = NULL,
           @CommandToExecute = NULL,
           @CreateProcedureStatement = @CreateProcedureStatement OUT,
           @CreateLogTableStatement = @CreateLogTableStatement OUT;

    EXEC tSQLt.AssertEqualsString @Expected = NULL, @Actual = @CreateLogTableStatement;     
END;
GO
GO
CREATE PROC SpyProcedureTests.[test Private_CreateProcedureSpy does create spy when @LogTableName is NULL]
AS
BEGIN
    EXEC('CREATE PROC dbo.OriginalInnerProcedure AS RETURN;');

    DECLARE @ProcedureObjectId INT = OBJECT_ID('dbo.OriginalInnerProcedure');

    DECLARE @CreateProcedureStatement NVARCHAR(MAX);
    DECLARE @CreateLogTableStatement NVARCHAR(MAX);

    EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement
           @ProcedureObjectId = @ProcedureObjectId,
           @OriginalProcedureName = 'dbo.SpiedInnerProcedure',  /*using different name to simulate renaming*/
           @LogTableName = NULL,
           @CommandToExecute = NULL,
           @CreateProcedureStatement = @CreateProcedureStatement OUT,
           @CreateLogTableStatement = @CreateLogTableStatement OUT;

    EXEC(@CreateProcedureStatement);

    EXEC tSQLt.AssertObjectExists @ObjectName = 'dbo.SpiedInnerProcedure';     

END;
GO
CREATE PROC SpyProcedureTests.[test SpyProcedure works with CLR procedures]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @expectedCommand NVARCHAR(MAX), @actualCommand NVARCHAR(MAX) AS EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].AssertResultSetsHaveSameMetaData;');
    
    EXEC tSQLt.SpyProcedure @ProcedureName = 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure @expectedCommand = 'Select 1 [Int]', @actualCommand = 'Select ''c'' [char]';

    SELECT expectedCommand, actualCommand INTO #Actual FROM dbo.InnerProcedure_SpyProcedureLog;
    SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
    INSERT INTO #Expected
    VALUES('Select 1 [Int]', 'Select ''c'' [char]');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO
CREATE PROC SpyProcedureTests.[test new Procedure Spy is marked as tSQLt.IsTempObject]
AS
BEGIN
  EXEC('CREATE PROCEDURE SpyProcedureTests.TempProcedure1 AS RETURN;');
  
  EXEC tSQLt.SpyProcedure @ProcedureName = 'SpyProcedureTests.TempProcedure1';
  
  SELECT name, value 
    INTO #Actual
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID('SpyProcedureTests.TempProcedure1')
     AND name = 'tSQLt.IsTempObject';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('tSQLt.IsTempObject',	1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


