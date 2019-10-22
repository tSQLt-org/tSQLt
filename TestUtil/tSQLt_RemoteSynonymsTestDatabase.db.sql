IF NOT EXISTS ( SELECT  *
                FROM    sys.databases
                WHERE   name = 'tSQLt_RemoteSynonymsTestDatabase' )
    BEGIN
        CREATE DATABASE tSQLt_RemoteSynonymsTestDatabase;
    END;
GO
USE tSQLt_RemoteSynonymsTestDatabase
GO

IF EXISTS ( SELECT  *
            FROM    sys.tables t
                    JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE   t.name = 'tbl'
                    AND s.name = 'MyTestClass' )
    BEGIN
        DROP TABLE MyTestClass.tbl;
    END;
GO

IF EXISTS ( SELECT  *
            FROM    sys.types t
                    JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE   t.name = 'UDT'
                    AND s.name = 'MyTestClass' )
    BEGIN
        DROP TYPE MyTestClass.UDT;
    END;
GO

IF EXISTS ( SELECT  *
            FROM    sys.schemas
            WHERE   name = 'MyTestClass' )
    BEGIN
        DROP SCHEMA MyTestClass;
    END;
GO

IF EXISTS ( SELECT  *
            FROM    sys.objects o
                    JOIN sys.schemas s ON s.schema_id = o.schema_id
            WHERE   o.name = 'TestView'
                    AND s.name = 'dbo' )
    BEGIN
        DROP VIEW dbo.TestView;
    END;


IF EXISTS ( SELECT  *
            FROM    sys.tables t
                    JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE   t.name = 'TestTable'
                    AND s.name = 'dbo' )
    BEGIN
        DROP TABLE dbo.TestTable;
    END;
GO

IF EXISTS ( SELECT  *
            FROM    sys.objects o
                    JOIN sys.schemas s ON s.schema_id = o.schema_id
            WHERE   o.name = 'NotATable'
                    AND s.name = 'dbo' )
    BEGIN
        DROP PROCEDURE dbo.NotATable;
    END;
GO

CREATE TABLE dbo.TestTable
    (
      c1 INT NULL ,
      c2 BIGINT NULL ,
      c3 VARCHAR(MAX) NULL
    );
GO
CREATE VIEW dbo.TestView
AS
    SELECT  *
    FROM    dbo.TestTable;;
GO

CREATE PROCEDURE dbo.NotATable
AS
    RETURN;
GO

CREATE SCHEMA MyTestClass;
GO

CREATE TYPE MyTestClass.UDT FROM NVARCHAR(20);
GO

CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT)
GO
USE $(NewDbName)
GO