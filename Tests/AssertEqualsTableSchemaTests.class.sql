EXEC tSQLt.NewTestClass 'AssertEqualsTableSchemaTests';
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test does not fail if tables are identical]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'AssertEqualsTableSchemaTests.Tbl1', @Actual = 'AssertEqualsTableSchemaTests.Tbl2';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has missing column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has additional column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has renamed column]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    Renamed INT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different data type]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different user data type]
AS
BEGIN
  CREATE TYPE AssertEqualsTableSchemaTests.TestType FROM NVARCHAR(256);

  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id INT PRIMARY KEY,
      NoKey NVARCHAR(256) NOT NULL
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id INT PRIMARY KEY,
      NoKey AssertEqualsTableSchemaTests.TestType NOT NULL
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test output contains type names]
AS
BEGIN
  CREATE TYPE AssertEqualsTableSchemaTests.TestType FROM INT;

  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id BIGINT PRIMARY KEY,
      NoKey INT
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id BIGINT PRIMARY KEY,
      NoKey AssertEqualsTableSchemaTests.TestType
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  DECLARE @ExpectedMessage NVARCHAR(MAX);
  SET @ExpectedMessage = '%56[[]int]%56[[]int]%'+CHAR(13)+CHAR(10)+
                         '%127[[]bigint]%127[[]bigint]%'+CHAR(13)+CHAR(10)+
                         '%56[[]int]%[[]AssertEqualsTableSchemaTests].[[]TestType]%'
  EXEC tSQLt_testutil.AssertFailMessageLike 
       @Command,@ExpectedMessage;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different NULLability]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NOT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different size]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(25) NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey NVARCHAR(256) NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different precision]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,2)
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(17,2)
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different scale]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,2)
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey DECIMAL(13,7)
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has different column order]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    NoKey INT,
    Id INT PRIMARY KEY
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different colation order]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey VARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CS_AS
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey VARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AI
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail if 2nd table has Column with different user data type schema]
AS
BEGIN
  IF(SCHEMA_ID('A')IS NULL)EXEC('CREATE SCHEMA A;');
  IF(SCHEMA_ID('B')IS NULL)EXEC('CREATE SCHEMA B;');
  CREATE TYPE A.AssertEqualsTableSchemaTestType FROM INT;
  CREATE TYPE B.AssertEqualsTableSchemaTestType FROM INT;
  EXEC('
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
      Id INT PRIMARY KEY,
      NoKey A.AssertEqualsTableSchemaTestType
    );
    CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
      Id INT PRIMARY KEY,
      NoKey B.AssertEqualsTableSchemaTestType
    );
  ');
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsTableSchema did not call Fail';
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail message starts with "Unexpected/missing columns\n"]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'';';
  DECLARE @Expected NVARCHAR(MAX); SET @Expected = 'Unexpected/missing column(s)'+CHAR(13)+CHAR(10)+'%';
  EXEC tSQLt_testutil.AssertFailMessageLike @Command, @Expected;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test fail message is prefixed with supplied message]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    NoKey INT NULL
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    NoKey BIGINT NULL
  );
  DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsTableSchema @Expected = ''AssertEqualsTableSchemaTests.Tbl1'', @Actual = ''AssertEqualsTableSchemaTests.Tbl2'', @Message=''{supplied message}'';';
  DECLARE @Expected NVARCHAR(MAX); SET @Expected = '{supplied message}%Unexpected%';
  EXEC tSQLt_testutil.AssertFailMessageLike @Command, @Expected;
END;
GO
CREATE PROCEDURE AssertEqualsTableSchemaTests.[test handles non-sequential column_id values]
AS
BEGIN
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl1(
    Id INT PRIMARY KEY,
    Col1 INT NULL, --2
    Gap1 INT NULL,
    Col2 INT NULL, --4
    Col3 INT NULL, --5
    Gap2 INT NULL,
    Gap3 INT NULL,
    Col4 INT NULL, --8
  );
  CREATE TABLE AssertEqualsTableSchemaTests.Tbl2(
    Id INT PRIMARY KEY,
    Col1 INT NULL, --2
    Col2 INT NULL, --3
    Gap1 INT NULL,
    Gap2 INT NULL,
    Col3 INT NULL, --6
    Col4 INT NULL, --7
  );
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap1;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap2;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl1 DROP COLUMN Gap3;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl2 DROP COLUMN Gap1;
  ALTER TABLE AssertEqualsTableSchemaTests.Tbl2 DROP COLUMN Gap2;
  EXEC tSQLt.AssertEqualsTableSchema @Expected = 'AssertEqualsTableSchemaTests.Tbl1', @Actual = 'AssertEqualsTableSchemaTests.Tbl2';
END;
GO

/*
SELECT 
    C.column_id,
    C.name,
    CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
    CAST(C.user_type_id AS NVARCHAR(MAX))+QUOTENAME(TU.name) user_type_id,
    C.max_length,
    C.precision,
    C.scale,
    C.collation_name,
    C.is_nullable,
    C.is_identity
  FROM sys.columns AS C
  JOIN sys.types AS TS
    ON C.system_type_id = TS.user_type_id
  JOIN sys.types AS TU
    ON C.user_type_id = TU.user_type_id


*/