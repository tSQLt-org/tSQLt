EXEC tSQLt.NewTestClass 'SpyProcedureTests_2008';
GO
CREATE TYPE SpyProcedureTests_2008.TableType1001 AS TABLE(SomeInt INT, SomeVarChar VARCHAR(10));
GO
CREATE PROC SpyProcedureTests_2008.[test SpyProcedure can have a table type parameter]
AS
BEGIN
  EXEC('CREATE PROC SpyProcedureTests_2008.InnerProcedure @P1 SpyProcedureTests_2008.TableType1001 READONLY AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

  EXEC tSQLt.SpyProcedure 'SpyProcedureTests_2008.InnerProcedure';

  DECLARE @TableParameter SpyProcedureTests_2008.TableType1001;
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(10,'S1');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(202,'V2');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(3303,'C3');

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'SpyProcedureTests_2008.InnerProcedure'
  EXEC @InnerProcedure @P1 = @TableParameter; 

  SELECT RowNode.value('SomeInt[1]','INT') SomeInt,RowNode.value('SomeVarChar[1]','VARCHAR(10)') SomeVarChar
    INTO #Actual
    FROM SpyProcedureTests_2008.InnerProcedure_SpyProcedureLog
   CROSS APPLY P1.nodes('P1/row') AS N(RowNode);  
  
  SELECT *
  INTO #Expected
  FROM @TableParameter AS TP;
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO
