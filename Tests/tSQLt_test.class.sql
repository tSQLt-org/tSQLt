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
EXEC tSQLt.NewTestClass 'tSQLt_test';
GO

CREATE PROC tSQLt_test.test_TestCasesAreWrappedInTransactions
AS
BEGIN
    DECLARE @ActualTranCount INT;

    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;

    EXEC ('CREATE PROC TestCaseA AS IF(@@TRANCOUNT < 2) RAISERROR(''TranCountMisMatch:%i'',16,10,@@TRANCOUNT);');

    EXEC tSQLt.Private_RunTest TestCaseA;

    SELECT @ActualTranCount=CAST(SUBSTRING(Msg,19,100) AS INT) FROM tSQLt.TestResult WHERE Msg LIKE 'TranCountMisMatch:%';

    ROLLBACK TRAN @TranName;
    COMMIT;

    IF (@ActualTranCount IS NOT NULL)
    BEGIN
        DECLARE @Message VARCHAR(MAX);
        SET @Message = 'Expected 2 transactions but was '+CAST(@ActualTranCount AS VARCHAR);

        EXEC tSQLt.Fail @Message;
    END;
END;
GO

CREATE PROC tSQLt_test.[test getNewTranName should generate a name]
AS
BEGIN
   DECLARE @Value CHAR(32)

   EXEC tSQLt.GetNewTranName @Value OUT;

   IF @Value IS NULL OR @Value = ''
   BEGIN
      EXEC tSQLt.Fail 'getNewTranName should have returned a name';
   END
END;
GO

CREATE PROC tSQLt_test.test_that_tests_in_testclasses_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'testMe')
    BEGIN
       EXEC tSQLt.Fail 'innertest.testMe did not get executed.';
    END;
END;
GO

CREATE PROC tSQLt_test.test_that_nontests_in_testclasses_do_not_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.do_not_test_me as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'do_not_test_me')
    BEGIN
       EXEC tSQLt.Fail 'innertest.do_not_test_me did get executed.';
    END;
END;
GO


CREATE PROC tSQLt_test.test_Run_handles_uncommitable_transaction
AS
BEGIN
    DECLARE @TranName sysname; 
    SELECT TOP(1) @TranName = TranName FROM tSQLt.TestResult WHERE Class = 'tSQLt_test' AND TestCase = 'test_Run_handles_uncommitable_transaction' ORDER BY Id DESC;
    EXEC ('CREATE PROC testUncommitable AS BEGIN CREATE TABLE t1 (i int); CREATE TABLE t1 (i int); END;');
    BEGIN TRY
        EXEC tSQLt.Run 'testUncommitable';
    END TRY
    BEGIN CATCH
      IF NOT EXISTS(SELECT 1
                      FROM tSQLt.TestResult
                     WHERE TestCase = 'testUncommitable'
                       AND Result = 'Error'
                       AND Msg LIKE '%There is already an object named ''t1'' in the database.[[]%]{testUncommitable,1}%'
                       AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
                   )
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not error correctly';
      END;
      IF(@@TRANCOUNT > 0)
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not rollback the transactions';
      END
      DELETE FROM tSQLt.TestResult
             WHERE TestCase = 'testUncommitable'
               AND Result = 'Error'
               AND Msg LIKE '%There is already an object named ''t1'' in the database.[[]%]{testUncommitable,1}%'
               AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
      BEGIN TRAN
      SAVE TRAN @TranName
    END CATCH
END;
GO


CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles table existing in several schemata]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  EXEC ('CREATE SCHEMA schemaB');
  EXEC ('CREATE SCHEMA schemaC');
  EXEC ('CREATE SCHEMA schemaD');
  EXEC ('CREATE SCHEMA schemaE');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaB.tableA (id INT);
  CREATE TABLE schemaC.tableA (id INT);
  CREATE TABLE schemaD.tableA (id INT);
  CREATE TABLE schemaE.tableA (id INT);
  
  SET @Expected = OBJECT_ID('schemaC.tableA');
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  EXEC tSQLt.FakeTable 'schemaB.tableA';
  EXEC tSQLt.FakeTable 'schemaC.tableA';
  EXEC tSQLt.FakeTable 'schemaD.tableA';
  EXEC tSQLt.FakeTable 'schemaE.tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('schemaC.tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles funky schema name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [s.c.h.e.m.a.A]');
  CREATE TABLE [s.c.h.e.m.a.A].tableA (id INT);
  
  SET @Expected = OBJECT_ID('[s.c.h.e.m.a.A].tableA');
  
  EXEC tSQLt.FakeTable '[s.c.h.e.m.a.A].tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('[s.c.h.e.m.a.A].tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint does not exist on given schema/table]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'constraint_does_not_exist', NULL);
  
  EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint exists on different table in same schema]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaA.tableB (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
 
  SELECT ConstraintObjectId 
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters and different constraint]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT differentConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'differentConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.differentConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Schema, Table, Constraint)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA', 'tableA', 'testConstraint2');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Table, Constraint, Schema)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('tableA', 'testConstraint2', 'schemaA');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record using 3 parameters in different orders]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT parms.id,result.ConstraintObjectId
  INTO #Actual
  FROM ( 
         SELECT 'SCT', 'schemaA', 'testConstraint2', 'tableA' UNION ALL
         SELECT 'TSC', 'tableA', 'schemaA', 'testConstraint2' UNION ALL
         SELECT 'CST', 'testConstraint2', 'schemaA', 'tableA' UNION ALL
         SELECT 'CTS', 'testConstraint2', 'tableA', 'schemaA' UNION ALL
         SELECT 'FNC', 'schemaA.tableA', NULL, 'testConstraint2' UNION ALL
         SELECT 'CFN', 'testConstraint2', 'schemaA.tableA', NULL UNION ALL
         SELECT 'CNF', 'testConstraint2', NULL, 'schemaA.tableA' UNION ALL
         SELECT 'NCF', NULL, 'testConstraint2', 'schemaA.tableA' UNION ALL
         SELECT 'NFC', NULL, 'schemaA.tableA', 'testConstraint2'
       )parms(id,p1,p2,p3)
  CROSS APPLY tSQLt.Private_ResolveApplyConstraintParameters(p1,p2,p3) result;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns two records when names are reused]
-- this test is to document that users with weirdly reused names will have problems...
AS
BEGIN
  EXEC ('CREATE SCHEMA nameA');
  EXEC ('CREATE SCHEMA nameC');
  CREATE TABLE nameA.nameB (id INT CONSTRAINT nameC CHECK (id > 0));
  CREATE TABLE nameC.nameA (id INT CONSTRAINT nameB CHECK (id > 0));

  SELECT *
    INTO #Expected
    FROM (
           SELECT OBJECT_ID('nameA.nameC')
           UNION ALL
           SELECT OBJECT_ID('nameC.nameB')
         )X(ConstraintObjectId);
  
  EXEC tSQLt.FakeTable 'nameA.nameB';
  EXEC tSQLt.FakeTable 'nameC.nameA';
  
  SELECT ConstraintObjectId
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('nameA', 'nameB', 'nameC');

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted table name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [sch emaA]');
  CREATE TABLE [sch emaA].[tab leA] (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable '[sch emaA].[tab leA]';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('[sch emaA].[tab leA]', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('[sch emaA].testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted constraint name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', '[test constraint]', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint returns only one row]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = COUNT(1) FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (1/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (2/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[[test constraint]]]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[[test constraint]]]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (3/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), 'test constraint');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO
----------------------------------------------------

CREATE PROC tSQLt_test.[test SpyProcedure works if spyee has 100 parameters with 8000 bytes each]
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
CREATE PROC tSQLt_test.[test SpyProcedure creates char parameters correctly]
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
CREATE PROC tSQLt_test.[test SpyProcedure creates binary parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @BINARY1 BINARY(1) =NULL,
             @BINARY8000 BINARY(8000) =NULL,
             @VARBINARY1 VARBINARY(1) =NULL,
             @VARBINARY8000 VARBINARY(8000) =NULL,
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

CREATE PROC tSQLt_test.[test SpyProcedure creates log which handles binary columns]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @VARBINARY8000 VARBINARY(8000) =NULL
          )
          AS BEGIN RETURN 0; END');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'
     
    EXEC dbo.InnerProcedure @VARBINARY8000=0x111122223333444455556666777788889999;

    DECLARE @Actual VARBINARY(8000);
    SELECT @Actual = VARBINARY8000 FROM dbo.InnerProcedure_SpyProcedureLog;
    
    EXEC tSQLt.AssertEquals 0x111122223333444455556666777788889999, @Actual;
END;
GO


CREATE PROC tSQLt_test.[test SpyProcedure creates nchar parameters correctly]
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
CREATE PROC tSQLt_test.[test SpyProcedure creates other parameters correctly]
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
CREATE PROC tSQLt_test.[test SpyProcedure fails with error if spyee has more than 1020 parameters]
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
  
END
GO
CREATE PROC tSQLt_test.[test f_Num(13) returns 13 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(13);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  INSERT #Expected(no)
  SELECT 1 no UNION ALL
  SELECT 2 no UNION ALL
  SELECT 3 no UNION ALL
  SELECT 4 no UNION ALL
  SELECT 5 no UNION ALL
  SELECT 6 no UNION ALL
  SELECT 7 no UNION ALL
  SELECT 8 no UNION ALL
  SELECT 9 no UNION ALL
  SELECT 10 no UNION ALL
  SELECT 11 no UNION ALL
  SELECT 12 no UNION ALL
  SELECT 13 no;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(0) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(0);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(-11) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(-11);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO

CREATE PROC tSQLt_test.[test that Private_SetFakeViewOn_SingleView allows a non-updatable view to be faked using FakeTable and then inserted into]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');

  EXEC('
      CREATE TABLE NewSchema.A (a1 int, a2 int);
      CREATE TABLE NewSchema.B (a1 int, b1 int, b2 int);
      CREATE TABLE NewSchema.C (b1 int, c1 int, c2 int);
      ');

  EXEC('      
      CREATE VIEW NewSchema.NewView AS
        SELECT A.a1, A.a2, B.b1, B.b2
          FROM NewSchema.A
          JOIN NewSchema.B ON A.a1 < B.a1
          JOIN NewSchema.C ON B.a1 > C.b1;
      ');
      
  -- SetFakeViewOn is executed in a separate batch (typically followed by a GO statement)
  -- than the code of the test case
  EXEC('    
      EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';
      ');
      
  EXEC('
      EXEC tSQLt.FakeTable ''NewSchema'', ''NewView'';
      INSERT INTO NewSchema.NewView (a1, a2, b1, b2) VALUES (1, 2, 3, 4);
      ');

  SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', 'NewSchema.NewView';
  
END
GO

CREATE PROC tSQLt_test.[test that not calling tSQLt.Private_SetFakeViewOff_SingleView before running tests causes an exception and tests not to be run]
AS
BEGIN
  DECLARE @ErrorMsg VARCHAR(MAX); SET @ErrorMsg = '';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  BEGIN TRY
    EXEC tSQLt.Private_RunTest 'TestClass.testExample';
  END TRY
  BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
  END CATCH

  IF @ErrorMsg NOT LIKE '%SetFakeViewOff%'
  BEGIN
    EXEC tSQLt.Fail 'Expected RunTestClass to raise an error because SetFakeViewOff was not executed';
  END;
END
GO

CREATE PROC tSQLt_test.[test that calling tSQLt.Private_SetFakeViewOff_SingleView before running tests allows tests to be run]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  EXEC('EXEC tSQLt.Private_SetFakeViewOff_SingleView @ViewName = ''NewSchema.NewView'';');
  
  BEGIN TRY
    EXEC tSQLt.Run 'TestClass';
  END TRY
  BEGIN CATCH
    DECLARE @Msg VARCHAR(MAX);SET @Msg = ERROR_MESSAGE();
    EXEC tSQLt.Fail 'Expected RunTestClass to not raise an error because Private_SetFakeViewOff_SingleView was executed. Error was:',@Msg;
  END CATCH
END
GO

CREATE PROC tSQLt_test.CreateNonUpdatableView
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_A (a1 int, a2 int);
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_B (a1 int, b1 int, b2 int);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

  SET @Cmd = '
    CREATE VIEW $$SCHEMA_NAME$$.$$VIEW_NAME$$ AS 
      SELECT A.a1, A.a2, B.b1, B.b2
        FROM $$SCHEMA_NAME$$.$$VIEW_NAME$$_A A
        JOIN $$SCHEMA_NAME$$.$$VIEW_NAME$$_B B ON A.a1 = B.a1;';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

END
GO

CREATE PROC tSQLt_test.AssertViewCanBeUpdatedIfFaked
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      EXEC tSQLt.FakeTable ''$$SCHEMA_NAME$$'', ''$$VIEW_NAME$$'';
      INSERT INTO $$SCHEMA_NAME$$.$$VIEW_NAME$$ (a1, a2, b1, b2) VALUES (1, 2, 3, 4);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
  
  SET @Cmd = '
    SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
    EXEC tSQLt.AssertEqualsTable ''#Expected'', ''$$SCHEMA_NAME$$.$$VIEW_NAME$$'';';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOn @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View1';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View2';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View3';
  
  -- Also check that triggers got created. Checking if a view is updatable is
  -- apparently unreliable, since SQL Server could have decided on this run
  -- that these views are updatable at compile time, even though they were not.
  IF (SELECT COUNT(*) FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn') <> 3
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be added.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF EXISTS (SELECT 1 FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName only removes triggers created by framework]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('CREATE TRIGGER NewSchema.View1_SetFakeViewOn ON NewSchema.View1 INSTEAD OF INSERT AS RETURN;');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE [name] = 'View1_SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected View1_SetFakeViewOn trigger not to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that SetFakeViewOn trigger throws meaningful error on execution]
AS
BEGIN
  --This test also tests that tSQLt can handle test that leave the transaction open, but in an uncommitable state.
  DECLARE @Msg VARCHAR(MAX); SET @Msg = 'no error';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  BEGIN TRY
    EXEC('INSERT NewSchema.View1 DEFAULT VALUES;');
  END TRY
  BEGIN CATCH
    SET @Msg = ERROR_MESSAGE();
  END CATCH;
  
  IF(@Msg NOT LIKE '%SetFakeViewOff%')
  BEGIN
    EXEC tSQLt.Fail 'Expected trigger to throw error. Got:',@Msg;
  END;
END
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name that does not exist returns null]
AS
BEGIN
	DECLARE @Actual INT;
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my schema');

	EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple bracket quoted schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema with brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if only unbracketed schema exists]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema when quoted with double quotes]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of double quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='"tSQLt_test"');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of bracket quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of unquoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test my.schema];');
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test my.schema');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my.schema');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does not exist]
AS
BEGIN
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_does_not_exist');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does exist but is not a test class]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test_notATestClass];');
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_notATestClass');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 1 if schema was created with NewTestClass]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_MyTestClass');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass handles bracket quoted test class names]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('[tSQLt_test_MyTestClass]');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns mostly nulls if testname is null]
AS
BEGIN
  SELECT * --forcing this test to test all columns
    INTO #Actual 
    FROM tSQLt.Private_ResolveName(null);

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (NULL, NULL, NULL, NULL, NULL, 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName if testname does not exist returns same info as if testname was null]
AS
BEGIN
  SELECT *
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('NeitherAnObjectNorASchema');

  SELECT *
    INTO #Expected
    FROM tSQLt.Private_ResolveName(null);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

--tSQLt.Private_ResolveTestName(testname)
--returns table
--->bit(class or name),
--  schema_id,
--  object_id (null if testname is a class),
--  quoted schema name,
--  quoted object name (null if testname is a class),
--  quoted full name (quoted schema name if testname is a class)
  
  
--x testname is null
--x testname cannot be resolved
--x testname is a schema name created with NewTestClass
--x testname is a schema name not created with NewTestClass
--x testname is a quoted schema name
--x testname is an object name that is a procedure and a test
--x testname is an object name that is not a procedure
--x testname is an object name that is a procedure but not a test
--x testname is a schema.object name
--x testname is a schema.object name, quoted
--x testname is a [schema.object] name, where dbo.[schema.object] exists and [schema].[object] exists
--testname is a schema name but also an object of the same name exists in dbo
--name is [test schema].[no test]

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns only schema info if testname is a schema created with CREATE SCHEMA]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL, '[InnerSchema]', NULL, '[InnerSchema]', 0, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a test class]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerTest');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase, isSchema)
  VALUES
    (1, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a quoted test class name]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT schemaId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerTest]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId)
  VALUES
    (SCHEMA_ID('InnerTest'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.TestObject');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'), '[InnerSchema]', '[TestObject]', '[InnerSchema].[TestObject]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName interprets object name correctly if schema of same name exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema1');
  EXEC ('CREATE SCHEMA InnerSchema2');
  EXEC ('CREATE TABLE InnerSchema1.InnerSchema2(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema1.InnerSchema2');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema1'), OBJECT_ID('InnerSchema1.InnerSchema2'), '[InnerSchema1]', '[InnerSchema2]', '[InnerSchema1].[InnerSchema2]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified quoted object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for TestProcedure]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[test inside] AS RETURN 0;');

  SELECT isTestClass, isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[test inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase)
  VALUES
    (0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for procedure that is not a test]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[NOtest inside] AS RETURN 0;');

  SELECT isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[NOtest inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestCase)
  VALUES
    (0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema.object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema.TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('dbo'), OBJECT_ID('dbo.[InnerSchema.TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema}.{object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('[InnerSchema].[TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a schema name where an object of same name exists in dbo]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE dbo.InnerSchema(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that is not in sys.objects]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF EXISTS (SELECT 1 FROM sys.objects WHERE NAME = @ObjectName)
  BEGIN
    EXEC tSQLt.Fail 'Created object name already exists in sys.objects, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that has not been previously generated]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF (@ObjectName = tSQLt.Private::CreateUniqueObjectName())
  BEGIN
    EXEC tSQLt.Fail 'Created object name was created twice, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a name which can be used to create a table]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SELECT @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  EXEC ('CREATE TABLE tSQLt_test.' + @ObjectName + '(i INT);');
END
GO

CREATE PROC tSQLt_test.[test Private_Print handles % signs]
AS
BEGIN
  DECLARE @msg NVARCHAR(MAX);
  SET @msg = 'No Message';
  BEGIN TRY
    EXEC tSQLt.Private_Print 'hello % goodbye', 16;
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'hello % goodbye', @msg;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail places parameters in correct order]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail 1, 2, 3, 4, 5, 6, 7, 8, 9, 0;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{1234567890}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail handles NULL parameters]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns no test classes when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns single test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_B');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns other important columns]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name,SchemaId
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name, SchemaId) VALUES ('tSQLt_test_dummy_A',SCHEMA_ID('tSQLt_test_dummy_A'));
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns one test on a test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.testA AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Name) VALUES ('testA');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no test on an empty test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there is only a helper procedure]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.xyz AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests recognizes all TeSt spellings]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.Test AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.TEST AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.tEsT AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (Name) VALUES ('Test');
  INSERT INTO #Expected (Name) VALUES ('TEST');
  INSERT INTO #Expected (Name) VALUES ('tEsT');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns multiple tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test2 AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test3 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test4 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test5 AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test1');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test2');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test3');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test4');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test5');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns relevant ids with tests]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');

  SELECT SchemaId, ObjectId
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (SchemaId, ObjectId) VALUES (SCHEMA_ID('tSQLt_test_dummy_A'), OBJECT_ID('tSQLt_test_dummy_A.test1'));
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes schema tSQLt]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = SCHEMA_ID('tSQLt');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt schema not removed';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes data type tSQLt.Private]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = TYPE_ID('tSQLt.Private');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.Private data type not removed';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes the tSQLt Assembly]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  
  SET @id = (SELECT assembly_id FROM sys.assemblies WHERE name = 'tSQLtCLR');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLtCLR assembly not removed';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Info() returns a row with a Version column containing latest build number]
AS
BEGIN
  DECLARE @Version NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @Version = Version
    FROM tSQLt.Info();
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  
  
  IF(@ClrInfo NOT LIKE '%version='+@Version+'%')
  BEGIN
    EXEC tSQLt.Fail 'Expected ''version=',@Version,''' to be part of ''',@ClrInfo,'''.'
  END
END;
GO
--ROLLBACK
--tSQLt_test