EXEC tSQLt.NewTestClass 'tSQLtclr_test';
GO

CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns BIGINT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''76456376'' AS BIGINT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'BIGINT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns BINARY(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''0x432643'' AS BINARY(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'BINARY(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns BIT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''1'' AS BIT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'BIT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns CHAR(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS CHAR(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'CHAR(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns DATETIME values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''12/27/2010 11:54:12.003'' AS DATETIME) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'DATETIME values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns DECIMAL(7,4) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''234.567'' AS DECIMAL(7,4)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'DECIMAL(7,4) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns FLOAT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''12345.6789'' AS FLOAT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'FLOAT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns IMAGE values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''XYZ'' AS IMAGE) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'IMAGE values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns INT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''13'' AS INT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'INT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns MONEY values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''12.95'' AS MONEY) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'MONEY values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns NCHAR(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS NCHAR(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'NCHAR(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns NTEXT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS NTEXT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'NTEXT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns NUMERIC(7,4) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''345.67'' AS NUMERIC(7,4)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'NUMERIC(7,4) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns NVARCHAR(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS NVARCHAR(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'NVARCHAR(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns NVARCHAR(MAX) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS NVARCHAR(MAX)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'NVARCHAR(MAX) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns REAL values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''12345.6789'' AS REAL) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'REAL values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns SMALLDATETIME values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''12/27/2010 09:35'' AS SMALLDATETIME) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'SMALLDATETIME values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns SMALLINT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''13'' AS SMALLINT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'SMALLINT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns SMALLMONEY values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''13.95'' AS SMALLMONEY) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'SMALLMONEY values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns SQL_VARIANT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS SQL_VARIANT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'SQL_VARIANT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns SYSNAME values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS SYSNAME) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'SYSNAME values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns TEXT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS TEXT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'TEXT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns TIMESTAMP values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''0x1234'' AS TIMESTAMP) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'TIMESTAMP values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns TINYINT values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''7'' AS TINYINT) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'TINYINT values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns UNIQUEIDENTIFIER values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'' AS UNIQUEIDENTIFIER) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'UNIQUEIDENTIFIER values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns VARBINARY(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS VARBINARY(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'VARBINARY(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns VARBINARY(MAX) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS VARBINARY(MAX)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'VARBINARY(MAX) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns VARCHAR(15) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS VARCHAR(15)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'VARCHAR(15) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns VARCHAR(MAX) values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''ABCDEF'' AS VARCHAR(MAX)) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'VARCHAR(MAX) values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
 
CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns XML values from one result set]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 1, 'SELECT CAST(''<xml>hi</xml>'' AS XML) AS val;'
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();
        EXEC tSQLt.Fail 'XML values caused exception in ResultsetFilter', @msg;
    END CATCH
END;
GO
